import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_sync_api.dart';

/// Seam de rafraîchissement ciblé consommé par les repos offline-first (leur
/// évite de dépendre de tout le câblage réseau — testables avec un no-op).
typedef LedgerRefresh =
    Future<void> Function(String studentId, String academicYearId);

/// Rafraîchissement CIBLÉ du grand-livre d'un élève (FRONT §2.1 fin / §6 step 2)
/// via l'endpoint **livré** `GET /sync/finance/ledger?studentId`. C'est le
/// « levier de fraîcheur » qui peuple le local d'un élève pré-existant avant un
/// encaissement, en attendant le pull en masse (§2.1, dormant côté backend).
///
/// - **Best-effort** : hors-ligne ou échec → no-op silencieux, l'UI lit le
///   cache tel quel (jamais d'erreur remontée depuis une lecture).
/// - **Déduppé** : un guard in-flight par (élève, année) garantit un seul appel
///   même si les sections Créances et Paiements le déclenchent en parallèle.
/// - Curseur `updatedSince` (int, dette B2 assumée tant que le contrat keyset
///   n'est pas livré) persisté par ressource `finance_ledger:<studentId>` ;
///   `synced_at` alimente la fraîcheur affichée (ADR-002).
class FinanceLedgerRefresher {
  final FinanceSyncApi _api;
  final FinanceLocalDao _dao;
  final SyncMetaDao _syncMetaDao;
  final ConnectivityService _connectivity;
  final Map<String, dynamic> _extras;
  final int Function() _now;
  final Map<String, Future<void>> _inFlight = {};

  FinanceLedgerRefresher({
    required FinanceSyncApi api,
    required FinanceLocalDao dao,
    required SyncMetaDao syncMetaDao,
    required ConnectivityService connectivity,
    required Map<String, dynamic> extras,
    int Function() now = systemClock,
  }) : _api = api,
       _dao = dao,
       _syncMetaDao = syncMetaDao,
       _connectivity = connectivity,
       _extras = extras,
       _now = now;

  static String _resource(String studentId) => 'finance_ledger:$studentId';

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
      // Pré-garde radio bon marché : hors-ligne → on lit le cache tel quel.
      if (!await _connectivity.isOnline()) return;
      final resource = _resource(studentId);
      final cursor = await _syncMetaDao.getCursor(resource);
      final delta = await _api.pullLedger(
        _extras,
        studentId,
        academicYearId,
        int.tryParse(cursor ?? ''),
      );
      final now = _now();
      await _dao.upsertLedger(
        charges: delta.charges.map((c) => c.toLocalModel(now)).toList(),
        payments: delta.payments.map((p) => p.toLocalModel(now)).toList(),
        allocations: delta.allocations.map((a) => a.toLocalModel()).toList(),
      );
      await _syncMetaDao.setCursor(
        resource,
        cursor: delta.serverCursor?.toString() ?? cursor,
        syncedAt: now,
      );
    } catch (_) {
      // Best-effort : toute erreur (réseau, parse, 304…) → cache inchangé.
    } finally {
      _inFlight.remove(key);
    }
  }
}
