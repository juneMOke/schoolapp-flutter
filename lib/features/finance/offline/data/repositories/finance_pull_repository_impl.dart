import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_pull_outcome.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_pull_repository.dart';

/// Page keyset incohérente : `hasMore` annoncé sans curseur qui progresse. Le
/// serveur nous demanderait de rejouer la même page indéfiniment.
class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

/// Issue d'un cycle de pull : le résultat déjà traduit, plus le seul signal
/// qu'un rejeu peut exploiter — un curseur rejeté (400) est dissoluble par un
/// bootstrap, aucune autre panne ne l'est.
class _CycleAttempt {
  final Either<Failure, FinancePullOutcome> result;
  final bool rejectedCursor;

  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Pulls KEYSET du grand-livre — miroir *lecture* de `openapi_billing_sync.yaml`
/// (§2.1 créances, §2.2 paiements ; ADR-008/009). Deux ressources indépendantes,
/// chacune paginée keyset et **résumable** : le jeton opaque est mémorisé à
/// CHAQUE page (`nextCursor` = progression → reprise après coupure), puis
/// remplacé par le `nextWatermark` en fin de cycle (départ du prochain cycle,
/// safety lag Δ déjà appliqué serveur).
///
/// **Jeton unique** (contrat 1.1.0) : les deux natures de jeton transitent par
/// le même paramètre `cursor` — le jeton mémorisé dans `sync_meta` est donc
/// renvoyé tel quel, sans préfixe ni discrimination (même convention que
/// l'Inscription, cf. `KeysetPageEnvelope.cursorToPersist`).
class FinancePullRepositoryImpl implements FinancePullRepository {
  final FinancePullApi _api;
  final FinanceLocalDao _dao;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  /// Clés `sync_meta` (une par ressource ; jetons distincts, cycles indépendants).
  static const String chargesResource = 'finance_student_charges';
  static const String paymentsResource = 'finance_payments';

  /// Taille de page (défaut serveur 100, borné [1, 500]).
  static const int pageLimit = 100;

  /// Dernier cycle **programmé** par ressource — la queue de la chaîne. Deux
  /// cycles concurrents sur la MÊME ressource liraient le même jeton de départ,
  /// pagineraient chacun de leur côté et réécriraient tous deux `sync_meta` : le
  /// plus lent **rembobinerait** le curseur du plus rapide, condamnant la
  /// tablette à re-tirer des pages déjà appliquées.
  ///
  /// Le cas est réel : `FinanceFeatureScope` lance le pull de masse au montage
  /// pendant que la page dessous déclenche, par sa lecture, le refresher — qui
  /// avance lui aussi le cycle des paiements. Le guard vit ICI, et non chez un
  /// appelant : c'est la ressource qu'il faut sérialiser, pas un usage.
  final Map<String, Future<Either<Failure, FinancePullOutcome>>> _tail = {};

  /// Cycle programmé mais **pas encore parti**, par ressource. Sur lui, et sur
  /// lui seul, on coalesce : il lira le curseur APRÈS l'appel de tout nouvel
  /// arrivant, donc il satisfait son besoin de fraîcheur. Borne la chaîne à
  /// « un qui tourne + un qui attend ».
  final Map<String, Future<Either<Failure, FinancePullOutcome>>> _queued = {};

  FinancePullRepositoryImpl({
    required FinancePullApi api,
    required FinanceLocalDao dao,
    required SyncMetaDao syncMetaDao,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _syncMetaDao = syncMetaDao,
       _requiredAuth = requiredAuth,
       _now = now;

  /// Sérialise les cycles d'une ressource — en **chaînant**, jamais en
  /// rejoignant un cycle déjà parti.
  ///
  /// Rejoindre était tentant (un seul appel réseau) mais **ment sur la
  /// fraîcheur** : un cycle en vol a lu son curseur AVANT l'appel du nouvel
  /// arrivant, donc il ne peut pas contenir un encaissement fait entre-temps sur
  /// l'autre poste. Le refresher, lui, conditionne la fraîcheur affichée à la
  /// réussite de ce cycle — il annoncerait « à jour » sur un delta antérieur au
  /// besoin. On garantit donc à chaque appelant un cycle qui **démarre après son
  /// appel**.
  ///
  /// La chaîne est bornée à deux (un qui tourne + un qui attend) : tant que le
  /// cycle en attente n'est pas parti, il satisfait tous les arrivants, qui s'y
  /// coalescent. Les cycles surnuméraires ne coûtent qu'un 304.
  Future<Either<Failure, FinancePullOutcome>> _guarded(
    String resource,
    Future<Either<Failure, FinancePullOutcome>> Function() cycle,
  ) {
    // Un cycle est programmé mais pas encore parti → il lira le curseur après
    // nous : il fait l'affaire.
    final queued = _queued[resource];
    if (queued != null) return queued;

    final tail = _tail[resource];
    late final Future<Either<Failure, FinancePullOutcome>> scheduled;
    final run = tail == null
        ? cycle()
        : tail.then((_) {
            // Il part maintenant : plus personne ne doit s'y coalescer.
            if (identical(_queued[resource], scheduled)) {
              _queued.remove(resource);
            }
            return cycle();
          });
    // Corps en BLOC, pas en expression : `Map.remove` renvoie la valeur retirée
    // — ici le Future qu'on est en train de terminer — et `whenComplete` attend
    // tout Future que son callback renvoie. En flèche, le cycle s'attendrait
    // lui-même : interblocage.
    scheduled = run.whenComplete(() {
      if (identical(_tail[resource], scheduled)) _tail.remove(resource);
      if (identical(_queued[resource], scheduled)) _queued.remove(resource);
    });
    // Aucun `await` entre la programmation et l'enregistrement : la pose du
    // guard est atomique vis-à-vis de la boucle d'événements.
    _tail[resource] = scheduled;
    if (tail != null) _queued[resource] = scheduled;
    return scheduled;
  }

  @override
  Future<Either<Failure, FinancePullOutcome>> syncStudentCharges() =>
      _guarded(chargesResource, _pullStudentCharges);

  Future<Either<Failure, FinancePullOutcome>> _pullStudentCharges() =>
      _keysetPull<StudentChargePageDto>(
        resource: chargesResource,
        request: (cursor) => _api.pullStudentCharges(
          _requiredAuth,
          cursor,
          pageLimit,
          null, // academicYearId : défaut serveur = année active
          null, // studentId : pull de masse (le ciblé passe par le refresher)
        ),
        apply: (page, syncedAt) async {
          await _dao.upsertLedger(
            charges: page.items.map((c) => c.toLocalModel(syncedAt)).toList(),
          );
          return page.items.length;
        },
      );

  @override
  Future<Either<Failure, FinancePullOutcome>> syncPayments() =>
      _guarded(paymentsResource, _pullPayments);

  Future<Either<Failure, FinancePullOutcome>> _pullPayments() =>
      _keysetPull<PaymentPageDto>(
        resource: paymentsResource,
        request: (cursor) =>
            _api.pullPayments(_requiredAuth, cursor, pageLimit, null),
        apply: (page, syncedAt) async {
          await _dao.upsertLedger(
            payments: page.items
                .map((i) => i.payment.toLocalModel(syncedAt))
                .toList(),
            allocations: page.items
                .expand((i) => i.allocationModels())
                .toList(),
          );
          return page.items.length;
        },
      );

  Future<Either<Failure, FinancePullOutcome>>
  _keysetPull<P extends KeysetPageDto<dynamic>>({
    required String resource,
    required Future<HttpResponse<P>> Function(String? cursor) request,
    required Future<int> Function(P page, int syncedAt) apply,
  }) async {
    final syncedAt = _now();
    final stored = await _syncMetaDao.getCursor(resource); // null = bootstrap
    final first = await _attemptCycle(
      resource,
      request,
      apply,
      syncedAt,
      from: stored,
    );
    // 400 = curseur illisible, forgé, de version inconnue, ou émis pour une
    // AUTRE ressource → le contrat impose de repartir du bootstrap. Sans ce
    // repli le jeton fautif serait rejoué à chaque cycle : la tablette ne
    // syncherait plus jamais, en silence (l'outcome est diagnostique). Couvre
    // aussi la migration des jetons préfixés `c…`/`w…` du contrat 1.0, encore en
    // base sur une tablette mise à jour.
    //
    // Le retry est HORS du `catch` : une exception levée DANS un bloc `catch`
    // n'est pas rattrapée par les `on …` frères, elle s'échapperait de
    // `_keysetPull` — qui promet de ne jamais lever (l'appelant est un
    // `unawaited`, l'erreur deviendrait une async error non gérée).
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(resource, cursor: null, syncedAt: syncedAt);
      // Un 400 au bootstrap n'est plus imputable au jeton : on n'insiste pas.
      return (await _attemptCycle(
        resource,
        request,
        apply,
        syncedAt,
        from: null,
      )).result;
    }
    return first.result;
  }

  /// Un cycle + sa traduction en [Either] (ne lève jamais). [_CycleAttempt
  /// .rejectedCursor] signale le seul cas rattrapable : le jeton envoyé a été
  /// rejeté, un bootstrap peut le dissoudre.
  Future<_CycleAttempt> _attemptCycle<P extends KeysetPageDto<dynamic>>(
    String resource,
    Future<HttpResponse<P>> Function(String? cursor) request,
    Future<int> Function(P page, int syncedAt) apply,
    int syncedAt, {
    required String? from,
  }) async {
    try {
      return _CycleAttempt(
        Right(await _runCycle(resource, request, apply, syncedAt, from: from)),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304) {
        // Rien de neuf : jeton conservé, fraîcheur bumpée. On RELIT le jeton
        // mémorisé au lieu de réécrire `from` : un 304 peut tomber en cours de
        // cycle (delta épuisé entre deux pages), et `_runCycle` a déjà persisté
        // la progression. Réécrire le jeton de DÉPART rembobinerait derrière les
        // pages appliquées — la tablette re-tirerait et ré-appliquerait les
        // mêmes lignes à chaque cycle, détruisant la résumabilité.
        final kept = await _syncMetaDao.getCursor(resource);
        await _syncMetaDao.setCursor(
          resource,
          cursor: kept,
          syncedAt: syncedAt,
        );
        return _CycleAttempt(
          Right(FinancePullOutcome.notModifiedAt(syncedAt, kept)),
        );
      }
      return _CycleAttempt(
        Left(ServerFailure(e.message ?? e.toString())),
        rejectedCursor: status == 400,
      );
    } on _IncoherentKeysetPage catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Incoherent keyset page: hasMore without a cursor')),
      );
    } on FormatException catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Invalid billing pull payload')),
      );
    } catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Unexpected error occurred')),
      );
    }
  }

  /// Un cycle complet depuis [from] : parcourt les pages, applique chacune en
  /// lot, et mémorise le jeton à CHAQUE page (reprise après coupure). Laisse
  /// remonter les [DioException] — l'appelant arbitre 304 / 400 / échec.
  Future<FinancePullOutcome> _runCycle<P extends KeysetPageDto<dynamic>>(
    String resource,
    Future<HttpResponse<P>> Function(String? cursor) request,
    Future<int> Function(P page, int syncedAt) apply,
    int syncedAt, {
    required String? from,
  }) async {
    var cursor = from;
    var upserted = 0;
    while (true) {
      final sent = cursor;
      final response = await request(sent);
      final env = response.data.page;
      upserted += await apply(response.data, syncedAt);

      // `nextCursor` (progression) tant que `hasMore`, sinon `nextWatermark`
      // (fin de cycle). `null` (page vide de fin) → jeton conservé.
      final nextToken = env.cursorToPersist;
      if (nextToken != null) cursor = nextToken;
      await _syncMetaDao.setCursor(
        resource,
        cursor: cursor,
        syncedAt: syncedAt,
      );

      if (!env.hasMore) break; // dernière page
      // Anti-boucle : le keyset est strictement croissant, donc `hasMore` avec
      // un `nextCursor` absent ou identique à celui envoyé = serveur défaillant.
      // On LÈVE au lieu de sortir en silence : sortir rendrait un Right
      // « updated », le curseur ne bougerait jamais, et chaque cycle rejouerait
      // la même page — une tablette bloquée pour toujours, comptée comme
      // synchronisée. Une panne serveur doit se voir.
      if (env.nextCursor == null || env.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }
    return upserted == 0
        ? FinancePullOutcome.notModifiedAt(syncedAt, cursor)
        : FinancePullOutcome(
            upserted: upserted,
            notModified: false,
            syncedAt: syncedAt,
            cursor: cursor,
          );
  }
}
