import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reconciliation_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';

/// Pulls Inscription — miroir *lecture* de `openApi.yaml` (section Sync,
/// ADR-008/009). Trois régimes :
///  - **référentiel** ([syncReferential]) : bundle full always-200, curseur =
///    simple marqueur de fraîcheur (`serverTime`) ;
///  - **cohorte N-1** ([syncReenrollmentCohort]) : ressource STATIQUE paginée
///    par `cursorId` (= studentId), parcourue **jusqu'à `bootstrapComplete`**
///    puis remplacée d'un bloc (swap atomique). Un roster interrompu (réseau) est
///    **jeté** : ni remplacement ni avance du marqueur → « jamais un demi-roster » ;
///  - **keyset** ([syncPreEnrollments]/[syncEnrollmentDelta]/[syncEnrollmentSnapshots])
///    : pagination par `cursor` opaque — on suit `nextCursor` tant que `hasMore`
///    (curseur mémorisé à CHAQUE page → reprise), puis on mémorise `nextWatermark`
///    (début du prochain cycle, Δ appliqué). `cursor` absent = bootstrap ; 304 =
///    rien de neuf (curseur conservé).
///
/// La grille tarifaire du bundle est déléguée à la Facturation via le seam
/// [replaceTariffs].
class EnrollmentPullRepositoryImpl implements EnrollmentPullRepository {
  final EnrollmentPullApi api;
  final EnrollmentReferentialDao referentialDao;
  final EnrollmentSeedDao seedDao;
  final EnrollmentReconciliationDao reconciliationDao;
  final Future<void> Function(
    List<FeeTariffLocalModel> tariffs,
    List<String> academicYearIds,
  )
  replaceTariffs;
  final SyncMetaDao syncMetaDao;
  final Map<String, dynamic> requiredAuth;
  final CurrentUserContext currentUser;
  final Clock now;

  /// Clés de curseur/fraîcheur dans `sync_meta` (une par ressource).
  static const String referentialResource = 'enrollment_referential';
  static const String cohortResource = 'enrollment_reenrollment_cohort';
  static const String preEnrollmentsResource = 'enrollment_pre_enrollments';
  static const String deltaResource = 'enrollments';

  /// Curseur du pull HYDRATANT — distinct du delta maigre (`deltaResource`) :
  /// les deux flux avancent indépendamment (le hydratant crée les lignes, le
  /// maigre ne fait que les réconcilier).
  static const String snapshotsResource = 'enrollment_snapshots';

  /// Taille de page keyset/cohorte (défaut serveur = 100, borné [1, 500]).
  static const int pageLimit = 100;

  const EnrollmentPullRepositoryImpl({
    required this.api,
    required this.referentialDao,
    required this.seedDao,
    required this.reconciliationDao,
    required this.replaceTariffs,
    required this.syncMetaDao,
    required this.requiredAuth,
    required this.currentUser,
    this.now = systemClock,
  });

  @override
  Future<Either<Failure, EnrollmentPullOutcome>> syncReferential() async {
    final syncedAt = now();
    try {
      final response = await api.pullReferential(requiredAuth);
      final applied = await _applyReferential(response.data, syncedAt);
      final cursor = response.data.serverTime;
      await syncMetaDao.setCursor(
        referentialResource,
        cursor: cursor,
        syncedAt: syncedAt,
      );
      return Right(_outcome(applied, syncedAt, cursor, serverTime: cursor));
    } on DioException catch (e) {
      return _mapDioError(e);
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid enrollment pull payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, EnrollmentPullOutcome>>
  syncReenrollmentCohort() async {
    final syncedAt = now();
    // Skip-si-complet **scopé par saison** : la cohorte N-1 est gelée sur la
    // saison (D3) — une fois le roster intégralement pullé, plus rien n'évolue
    // côté serveur, donc aucun intérêt à re-scanner à chaque montage du module.
    // Le marqueur est keyé par l'année académique COURANTE (résolue localement
    // via `ref_academic_years`, peuplée par le pull référentiel qui précède) :
    // un rollover d'année → nouvelle clé → re-pull automatique (la base offline
    // survit au logout/rollover — voir OFFLINE_GAP_ANALYSIS). Le curseur n'étant
    // posé QU'au succès total (jamais sur un roster partiel/échoué), sa présence
    // vaut « roster complet en cache pour cette saison » → court-circuit sans
    // réseau. Année non résolue (base fraîche) → clé de repli non scopée.
    final currentYearId = await seedDao.findCurrentAcademicYearId();
    final markerKey = _cohortMarkerKey(currentYearId);
    final done = await syncMetaDao.getCursor(markerKey);
    if (done != null) {
      return Right(EnrollmentPullOutcome.notModifiedAt(syncedAt, done));
    }
    try {
      final all = <ReenrollmentCandidateDto>[];
      String? cursorId; // null = première page
      String serverTime = '';
      var complete = false;
      while (true) {
        final response = await api.pullReenrollmentCohort(
          requiredAuth,
          cursorId,
          null,
          pageLimit,
        );
        final body = response.data;
        all.addAll(body.items);
        serverTime = body.serverTime;
        if (body.bootstrapComplete) {
          complete = true;
          break;
        }
        // Gardes anti-boucle : sans complétion, un `nextCursorId` absent OU
        // identique à celui envoyé (keyset studentId strictement croissant) =
        // aucun progrès → roster incomplet (jeté plus bas), jamais une boucle
        // infinie qui gonfle `all` en mémoire (symétrique de `_keysetPull`).
        if (body.nextCursorId == null || body.nextCursorId == cursorId) break;
        cursorId = body.nextCursorId;
      }
      if (!complete) {
        // Roster partiel : NE PAS remplacer le snapshot ni avancer le marqueur
        // (un device interrompu ne doit pas croire tenir tout le roster). Rejoué
        // depuis la première page au prochain cycle.
        return const Left(
          ServerFailure('Reenrollment cohort roster incomplete'),
        );
      }
      final upserted = await seedDao.replaceReenrollmentCohort(
        all,
        syncedAt: syncedAt,
      );
      await syncMetaDao.setCursor(
        markerKey,
        cursor: serverTime,
        syncedAt: syncedAt,
      );
      return Right(
        _outcome(upserted, syncedAt, serverTime, serverTime: serverTime),
      );
    } on DioException catch (e) {
      return _mapDioError(e);
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid enrollment pull payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, EnrollmentPullOutcome>> syncPreEnrollments() =>
      _keysetPull<PreEnrollmentDto, PreEnrollmentsPageDto>(
        resource: preEnrollmentsResource,
        request: (cursor) =>
            api.pullPreEnrollments(requiredAuth, cursor, pageLimit),
        apply: (items, syncedAt) =>
            seedDao.upsertPreEnrollments(items, syncedAt: syncedAt),
      );

  @override
  Future<Either<Failure, EnrollmentPullOutcome>> syncEnrollmentDelta() async {
    // ⚠️ LE DELTA NE PART PAS SUR UNE BASE JAMAIS HYDRATÉE — il y brûlerait son
    // backlog, en silence.
    //
    // Le delta est maigre : `applyEnrollmentDelta` ne fait qu'UPDATE des lignes
    // que seul l'hydratant INSERT. Sans hydratation, chaque page ne met à jour
    // rien du tout — mais `_keysetPull` mémorise le jeton à CHAQUE page, sans
    // jamais regarder `upserted`. Le backlog serveur est donc consommé et le
    // curseur avancé au-delà de dossiers que plus rien ne redemandera : les
    // modifications de cette fenêtre sont perdues jusqu'à un rebootstrap.
    //
    // Et l'incident est invisible : zéro ligne appliquée est replié en
    // `notModified` par `_outcome`, exactement comme un cycle sain. Pas
    // d'erreur, pas de compteur, aucun événement de bus — rien à quoi
    // s'accrocher pour comprendre pourquoi des dossiers sont figés.
    //
    // La garde vit ICI, dans le repository, et non dans le `PullHandler` :
    // `SyncEnrollmentPullsUseCase` appelle ces méthodes EN DIRECT au montage
    // des FeatureScope Inscription, Facturation et Documents — c'est le chemin
    // le plus emprunté, bien plus que le coordinateur qui n'a que deux
    // déclencheurs. Une garde posée dans le handler l'aurait laissé passer.
    //
    // Le curseur de l'hydratant fait office de témoin : il n'existe qu'après
    // une première page appliquée. Ce n'est pas un drapeau de bootstrap
    // COMPLET — cette paire n'en a pas, contrairement à `attendance` ou
    // `schedule` — mais il suffit à distinguer « jamais hydraté » du reste, qui
    // est le seul cas où le delta détruit.
    //
    // Dans un cycle normal l'ordre d'enregistrement fait passer l'hydratant en
    // premier : au moment où le delta s'exécute, le curseur est déjà posé et la
    // garde laisse passer. Elle ne mord donc que sur un ordre inversé, ou sur
    // un chemin qui tirerait le delta seul.
    final hydrated = await _hasEverHydrated();
    if (!hydrated) {
      // NI appel réseau, NI écriture : surtout pas de `setCursor`, qui
      // bumperait la fraîcheur et ferait lire « à jour » à une ressource qu'on
      // vient délibérément de ne pas demander.
      return Right(EnrollmentPullOutcome.notModifiedAt(now(), null));
    }
    return _keysetPull<EnrollmentDeltaDto, EnrollmentDeltaPageDto>(
      resource: deltaResource,
      request: (cursor) =>
          api.pullEnrollmentDelta(requiredAuth, cursor, null, pageLimit),
      apply: (items, syncedAt) =>
          reconciliationDao.applyEnrollmentDelta(items, syncedAt: syncedAt),
    );
  }

  /// L'hydratant a-t-il déjà posé son curseur ?
  ///
  /// Défensif comme le reste de la couche : une base indisponible rend `true`,
  /// pour que la garde ne puisse jamais devenir elle-même la cause d'un flux
  /// qui ne descend plus. Le pire qu'elle risque alors est de laisser passer un
  /// delta qu'elle aurait retenu — le comportement d'avant cette garde.
  Future<bool> _hasEverHydrated() async {
    try {
      return await syncMetaDao.getCursor(snapshotsResource) != null;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<Either<Failure, EnrollmentPullOutcome>> syncEnrollmentSnapshots() =>
      _keysetPull<EnrollmentAggregateSnapshotDto, EnrollmentSnapshotPageDto>(
        resource: snapshotsResource,
        request: (cursor) =>
            api.pullEnrollmentSnapshots(requiredAuth, cursor, null, pageLimit),
        apply: (items, syncedAt) => reconciliationDao.upsertEnrollmentSnapshots(
          items,
          syncedAt: syncedAt,
        ),
      );

  /// Squelette de pull **keyset** (préinscriptions / delta / snapshots) :
  /// parcourt les pages depuis le curseur mémorisé (`null` = bootstrap), applique
  /// chaque page en lot, et **mémorise le jeton à CHAQUE page** — `nextCursor`
  /// tant que `hasMore` (reprise en cas d'interruption), puis `nextWatermark` en
  /// fin de cycle (Δ appliqué). Le 304 (rien de neuf) arrive en [DioException] :
  /// fraîcheur bumpée, curseur conservé. Ne lève pas.
  Future<Either<Failure, EnrollmentPullOutcome>>
  _keysetPull<I, P extends KeysetPageDto<I>>({
    required String resource,
    required Future<HttpResponse<P>> Function(String? cursor) request,
    required Future<int> Function(List<I> items, int syncedAt) apply,
  }) async {
    final syncedAt = now();
    try {
      var cursor = await syncMetaDao.getCursor(resource); // null = bootstrap
      var upserted = 0;
      String? lastServerTime;
      while (true) {
        final sent = cursor;
        final response = await request(sent);
        final body = response.data;
        if (body.items.isNotEmpty) {
          upserted += await apply(body.items, syncedAt);
        }
        final env = body.page;
        lastServerTime = env.serverTime;
        // `nextCursor` (progression) tant que `hasMore`, sinon `nextWatermark`
        // (fin de cycle). `null` (page vide de fin) → curseur conservé.
        final nextToken = env.cursorToPersist;
        if (nextToken != null) cursor = nextToken;
        await syncMetaDao.setCursor(
          resource,
          cursor: cursor,
          syncedAt: syncedAt,
        );
        if (!env.hasMore) break; // dernière page
        // Gardes anti-boucle : le keyset est strictement croissant, donc un
        // `nextCursor` absent OU identique à celui envoyé = serveur défaillant
        // (sinon on rejouerait la même page à l'infini — cf. historique verrou
        // sqflite).
        if (env.nextCursor == null || env.nextCursor == sent) break;
      }
      return Right(
        _outcome(upserted, syncedAt, cursor, serverTime: lastServerTime),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        final previous = await syncMetaDao.getCursor(resource);
        await syncMetaDao.setCursor(
          resource,
          cursor: previous,
          syncedAt: syncedAt,
        );
        return Right(EnrollmentPullOutcome.notModifiedAt(syncedAt, previous));
      }
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid enrollment pull payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  /// École/années/cycles/niveaux via [referentialDao] + grille tarifaire via
  /// [replaceTariffs] (`label` serveur nullable replié sur `fee_code` :
  /// colonne NOT NULL), le tout **scopé** aux années du bundle — `current` +
  /// `previous` s'il est présent (purge des lignes disparues du snapshot).
  /// Deux transactions distinctes (le seam ne traverse pas les modules) : un
  /// échec des tarifs laisse le référentiel appliqué mais le curseur
  /// N'AVANCE PAS → l'intégralité est rejouée au pull suivant.
  Future<int> _applyReferential(ReferentialBundleDto body, int syncedAt) async {
    final upserted = await referentialDao.upsertReferential(
      body,
      syncedAt: syncedAt,
      schoolId: currentUser.schoolId ?? '',
    );
    // Portion réservée (ADR-014 §4) : le serveur envoie `feeTariffs: null` —
    // et non `[]` — quand l'appelant n'a pas `finance.grid.read`. `null` dit
    // « je ne te la montre pas », jamais « cette école n'a pas de tarifs ».
    // Replier l'un sur l'autre ferait lire à la purge scopée un ordre de tout
    // supprimer : la purge ne connaît que l'année, pas le compte, donc sur une
    // tablette partagée un pull sans ce droit effacerait la grille dont dépend
    // l'inscription hors ligne d'un autre poste. On ne purge donc QUE les
    // années dont le bundle a réellement porté sa section — une section
    // présente mais vide reste, elle, un ordre de purge légitime.
    final tariffBundles = <ReferentialYearBundleDto>[
      if (body.current.feeTariffs != null) body.current,
      if (body.previous?.feeTariffs != null) body.previous!,
    ];
    if (tariffBundles.isEmpty) return upserted;

    final allTariffs = [for (final b in tariffBundles) ...b.feeTariffs!];
    final yearIds = <String>{
      for (final b in tariffBundles) b.academicYear.id,
      for (final b in tariffBundles)
        for (final g in b.schoolLevelGroups) g.academicYearId,
      for (final t in allTariffs) t.academicYearId,
    }.toList(growable: false);
    await replaceTariffs(
      allTariffs
          .map(
            (t) => FeeTariffLocalModel(
              id: t.id,
              academicYearId: t.academicYearId,
              schoolLevelId: t.schoolLevelId,
              schoolLevelGroupId: t.schoolLevelGroupId,
              feeCode: t.feeCode,
              label: t.label ?? t.feeCode,
              amountInCents: t.amountInCents,
              currency: t.currency,
              dueAt: t.dueAt,
              syncedAt: syncedAt,
              updatedAt: syncedAt,
            ),
          )
          .toList(growable: false),
      yearIds,
    );
    return upserted + allTariffs.length;
  }

  /// Bilan d'un pull : `notModified` si aucune ligne locale écrite (curseur tout
  /// de même mémorisé — delta vide, ADR-008), `updated` sinon. [serverTime]
  /// (ISO-8601) alimente [EnrollmentPullOutcome.serverTimeMs] sur la branche
  /// `updated` uniquement.
  EnrollmentPullOutcome _outcome(
    int applied,
    int syncedAt,
    String? cursor, {
    String? serverTime,
  }) => applied == 0
      ? EnrollmentPullOutcome.notModifiedAt(syncedAt, cursor)
      : EnrollmentPullOutcome(
          upserted: applied,
          notModified: false,
          syncedAt: syncedAt,
          cursor: cursor,
          serverTimeMs: serverTime == null
              ? null
              : EpochIsoHelper.tryToEpochMs(serverTime),
        );

  Either<Failure, EnrollmentPullOutcome> _mapDioError(DioException e) {
    if (e.error is Failure) return Left(e.error as Failure);
    return const Left(NetworkFailure('Network error occurred'));
  }

  /// Clé `sync_meta` du marqueur « roster complet » de la cohorte, **scopée par
  /// l'année académique courante** (`enrollment_reenrollment_cohort:<year>`) pour
  /// s'invalider seule au rollover d'année. Année non résolue (référentiel non
  /// encore synchronisé) → clé de repli non scopée [cohortResource].
  String _cohortMarkerKey(String? currentYearId) =>
      currentYearId == null ? cohortResource : '$cohortResource:$currentYearId';
}
