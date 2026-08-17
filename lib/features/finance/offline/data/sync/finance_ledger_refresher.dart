import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_api.dart';

/// Seam de rafraîchissement ciblé consommé par les repos offline-first (leur
/// évite de dépendre de tout le câblage réseau — testables avec un no-op).
typedef LedgerRefresh =
    Future<void> Function(String studentId, String academicYearId);

/// Seam du pull GLOBAL des paiements (cycle keyset résumable, curseur partagé
/// avec le pull de masse). Injecté plutôt qu'appelé en direct : le contrat n'a
/// pas d'endpoint paiements scopé élève — le delta global EST le seul moyen de
/// voir les encaissements de l'autre poste.
///
/// Renvoie `true` si le cycle a abouti : la fraîcheur affichée en dépend, elle
/// ne doit pas couvrir un historique qu'on n'a pas réussi à tirer.
///
/// ⚠️ **Ce que la DI branche derrière ce seam passe par le coordinateur**
/// (`CoordinatorPaymentsSync`), et ce n'est pas un détail de câblage. Ce flux-ci
/// est global : il porte la clé de plan `finance.payments` et un handler
/// enregistré. Seule l'AUTRE jambe de ce refresher — le point read scopé
/// `finance_ledger:<studentId>` — est légitimement exemptée du coordinateur, sa
/// clé étant dynamique par élève. Rebrancher ce seam en direct sur
/// `FinancePullRepository.syncPayments()` rouvrirait une porte dérobée : le pull
/// redeviendrait plus large que le plan du profil.
typedef PaymentsSync = Future<bool> Function();

/// Rafraîchissement CIBLÉ des créances d'un élève (FRONT §2.1 fin / §6 step 2)
/// via l'endpoint keyset `GET /api/v1/sync/student-charges?studentId=`. C'est le
/// « levier de fraîcheur » qui peuple le local d'un élève pré-existant avant un
/// encaissement, en complément du pull en masse (§2.1).
///
/// - **Best-effort** : hors-ligne ou échec → no-op silencieux, l'UI lit le
///   cache tel quel (jamais d'erreur remontée depuis une lecture).
/// - **Déduppé** : un guard in-flight par (élève, année) garantit un seul appel
///   même si les sections Créances et Paiements le déclenchent en parallèle.
/// - **Point read sur les créances** : ne touche PAS le curseur du pull de
///   masse ; il ne fait qu'UPSERT les créances autoritaires de l'élève et
///   bumper `synced_at` (la fraîcheur affichée, ADR-002).
/// - **Paiements** : le contrat n'expose pas d'endpoint paiements scopé élève
///   (`GET /sync/payments` ne prend que `cursor`/`limit`/`academicYearId`) — on
///   avance donc le **cycle global** via [PaymentsSync]. Sans lui, ce seam
///   tiendrait une promesse fausse : il est le point de fraîcheur DEVANT la
///   lecture de l'historique, et cet historique est **replié en « total payé »**
///   à l'écran (`facturation_detail_payments_section`). Un encaissement fait au
///   poste A il y a 2 min resterait invisible au poste B, qui afficherait un
///   total sous-estimé et **réencaisserait**. Le cycle étant keyset, le delta
///   est vide la plupart du temps : le coût réel est un 304.
class FinanceLedgerRefresher {
  final FinancePullApi _api;
  final FinanceLocalDao _dao;
  final SyncMetaDao _syncMetaDao;
  final ConnectivityService _connectivity;
  final SessionCredentialsProbe _credentialsProbe;
  final Map<String, dynamic> _extras;
  final PaymentsSync? _syncPayments;
  final int Function() _now;
  final Map<String, Future<void>> _inFlight = {};

  static const int _pageLimit = 100;

  /// Temps maximal qu'une LECTURE accepte d'attendre le cycle global des
  /// paiements. Au-delà, l'écran sert le local (offline-first) et le cycle
  /// poursuit en tâche de fond.
  final Duration _paymentsDeadline;

  FinanceLedgerRefresher({
    required FinancePullApi api,
    required FinanceLocalDao dao,
    required SyncMetaDao syncMetaDao,
    required ConnectivityService connectivity,
    required SessionCredentialsProbe credentialsProbe,
    required Map<String, dynamic> extras,
    PaymentsSync? syncPayments,
    Duration paymentsDeadline = const Duration(seconds: 4),
    int Function() now = systemClock,
  }) : _api = api,
       _dao = dao,
       _syncMetaDao = syncMetaDao,
       _connectivity = connectivity,
       _credentialsProbe = credentialsProbe,
       _extras = extras,
       _syncPayments = syncPayments,
       _paymentsDeadline = paymentsDeadline,
       _now = now;

  static String _resource(String studentId) => 'finance_ledger:$studentId';

  /// Sonde défaillante (storage indisponible…) : ne pas bloquer la lecture —
  /// même politique fail-open que `SyncStatusCubit._canAuthenticate()`.
  Future<bool> _canAuthenticate() async {
    try {
      return await _credentialsProbe.canAuthenticate();
    } catch (_) {
      return true;
    }
  }

  /// Epoch ms de la dernière synchro réussie du grand-livre de l'élève (pour
  /// l'affichage de fraîcheur « à jour à HHhMM », ADR-002). Null si jamais.
  Future<int?> lastSyncedAt(String studentId) =>
      _syncMetaDao.getSyncedAt(_resource(studentId));

  Future<void> refresh(String studentId, String academicYearId) {
    final key = '$studentId|$academicYearId';
    return _inFlight[key] ??= _run(studentId, academicYearId, key);
  }

  Future<void> _run(String studentId, String academicYearId, String key) async {
    try {
      // Pré-garde radio bon marché : hors-ligne → on lit le cache tel quel,
      // et AUCUN des deux pulls ne part.
      if (!await _connectivity.isOnline()) return;
      // Gate crédentiels : sans jetons utilisables, les deux pulls partiraient
      // en 401 systématique — ce point read est déclenché à CHAQUE lecture de
      // la fiche élève (bien plus fréquent que le montage du scope Facturation),
      // donc bien plus coûteux à laisser taper le réseau pour rien.
      if (!await _canAuthenticate()) return;
      final now = _now();
      // Le cycle des paiements ne part QUE si le miroir des créances est à jour.
      // Ordre non négociable (cf. le ⚠️ de `enrollment_finance_offline_di.dart`)
      // : avancer les paiements sur des créances périmées, c'est le sens de
      // panne qui fait RÉENCAISSER. Créances KO → on ne touche à rien.
      if (!await _refreshCharges(studentId, academicYearId, now)) return;
      if (!await _pullPaymentsBestEffort()) return;
      // Fraîcheur estampillée SEULEMENT ici : c'est la promesse « à jour à
      // HHhMM » affichée sous les totaux (ADR-002), et elle couvre les DEUX
      // faces du grand-livre. La poser après les seules créances mentirait —
      // l'écran replie l'historique des paiements en « total payé », et
      // afficherait « à jour » sur un historique périmé.
      await _syncMetaDao.setCursor(
        _resource(studentId),
        cursor: null,
        syncedAt: now,
      );
    } catch (_) {
      // Filet ultime : une LECTURE ne remonte JAMAIS d'erreur de synchro. Les
      // deux pulls avalent déjà les leurs, mais `isOnline()` et le `setCursor`
      // de fraîcheur restent ici — s'ils lèvent après un pull réussi (DB
      // verrouillée, disque plein), l'UI doit servir le cache tel quel, pas
      // faire échouer la lecture (les repos appelants mappent tout jet en
      // `Left(StorageFailure)`).
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Le point read des créances de l'élève. Avale ses erreurs : une lecture ne
  /// remonte jamais d'erreur, l'UI sert le cache tel quel. Renvoie `true` si le
  /// miroir local des créances est à jour — **304 compris** : « rien n'a
  /// changé » veut dire que le miroir est bon, pas qu'il a échoué.
  Future<bool> _refreshCharges(
    String studentId,
    String academicYearId,
    int now,
  ) async {
    try {
      // Pull keyset scopé à l'élève (petit volume : ~5 créances → 1 page). On
      // suit `nextCursor` en mémoire par prudence, sans persister de curseur
      // (c'est un point read, pas un cycle résumable).
      String? cursor;
      while (true) {
        final response = await _api.pullStudentCharges(
          _extras,
          cursor,
          _pageLimit,
          academicYearId,
          studentId,
        );
        final page = response.data;
        if (page.items.isNotEmpty) {
          await _dao.upsertLedger(
            charges: page.items.map((c) => c.toLocalModel(now)).toList(),
          );
        }
        final env = page.page;
        if (!env.hasMore ||
            env.nextCursor == null ||
            env.nextCursor == cursor) {
          break;
        }
        cursor = env.nextCursor;
      }
      return true;
    } on DioException catch (e) {
      // 304 = « rien n'a changé depuis ce jeton » : le miroir EST à jour. Le
      // traiter comme un échec couperait l'historique des paiements exactement
      // dans le cas nominal (élève déjà à jour).
      return e.response?.statusCode == 304;
    } catch (_) {
      return false; // cache inchangé, l'UI le sert tel quel
    }
  }

  /// Avance le cycle keyset GLOBAL des paiements (delta habituellement vide →
  /// 304). Best-effort : le seam renvoie un `Either` et ne lève pas, mais on
  /// garde le filet — une lecture ne doit jamais échouer sur la synchro.
  /// Renvoie `true` si l'historique local est à jour.
  ///
  /// **Borné par [_paymentsDeadline]** : ce cycle est global et non paginé côté
  /// appelant — sur une tablette neuve (curseur absent → bootstrap) il tirerait
  /// TOUT l'historique de l'école avant que l'écran n'affiche des lignes déjà
  /// présentes en local, ce qui trahirait la promesse offline-first. Au-delà du
  /// délai on rend la main SANS annuler le cycle : il continue en tâche de fond
  /// (son propre guard le sérialise) et fera avancer le curseur pour la
  /// prochaine lecture. On renvoie alors `false` — l'historique n'est pas
  /// garanti à jour, donc aucune fraîcheur ne sera affichée : borner la latence
  /// ne doit pas devenir un mensonge.
  /// La seule jambe PAIEMENTS, exposée pour que le **câblage** soit éprouvable.
  ///
  /// Ce n'est pas du confort de test. Ce seam a été la treizième porte dérobée
  /// du lot F6 : il tirait le flux global en direct sur le repository, hors du
  /// plan. Le refermer, c'est une ligne de DI — et une ligne de DI est
  /// exactement ce que ce chantier a appris à ne jamais supposer branché : cinq
  /// gardes ont déjà été écrites, testées, et jamais injectées, la suite entière
  /// restant verte.
  ///
  /// Prouver que `CoordinatorPaymentsSync` est *enregistré* ne prouve pas que
  /// c'est LUI qu'on appelle ici. Seul ce point d'entrée permet de le vérifier
  /// sur le conteneur réel, sans que le point read des créances ne parte taper
  /// le réseau (cf. `offline_pull_registration_order_test.dart`).
  @visibleForTesting
  Future<bool> debugPullPaymentsOnly() => _pullPaymentsBestEffort();

  Future<bool> _pullPaymentsBestEffort() async {
    final sync = _syncPayments;
    if (sync == null) return true; // pas de seam câblé : rien à attendre
    // Ré-emballage dans un future dont le type RÉIFIÉ est bien `Future<bool>`,
    // AVANT le `.timeout`. Un seam qui échoue sans jamais suspendre rend un
    // `Future<Never>` (type statique `Future<bool>`, type réifié plus étroit) ;
    // `.timeout` exige alors un `onTimeout` en `() => Never`, et notre
    // `() => false` lève un TypeError — que le `catch` ci-dessous avalerait, en
    // masquant la vraie erreur et en la laissant remonter non gérée à la zone.
    // `Future.sync` ne réglerait rien : il RENVOIE le future tel quel quand c'en
    // est déjà un, sans le normaliser.
    Future<bool> cycle() async => sync();
    try {
      return await cycle().timeout(_paymentsDeadline, onTimeout: () => false);
    } catch (_) {
      return false; // l'historique restera au dernier état connu
    }
  }
}
