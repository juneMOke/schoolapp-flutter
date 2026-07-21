import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';

/// Bilan d'un cycle de pull (diagnostic / UI).
class PullRunReport {
  final bool skipped;
  final bool offline;
  final int updated;
  final int notModified;
  final int failed;

  /// Horloge **serveur** (epoch ms) la plus récente observée ce cycle, tous
  /// handlers confondus (max des [PullOutcome.serverTimeMs] non-null) — sert
  /// de date de "dernière synchro" (badge). `null` si aucun handler n'a
  /// ramené de donnée avec `serverTime` (rien de neuf partout, ou ressources
  /// dont le contrat n'expose pas encore ce champ).
  final int? latestServerTimeMs;

  const PullRunReport({
    this.skipped = false,
    this.offline = false,
    this.updated = 0,
    this.notModified = 0,
    this.failed = 0,
    this.latestServerTimeMs,
  });

  const PullRunReport.skipped() : this(skipped: true);
  const PullRunReport.offline() : this(offline: true);

  int get processed => updated + notModified + failed;
}

/// Orchestrateur du **pull delta** (SOC-1) — pendant *lecture* du `SyncEngine`
/// (qui, lui, pousse l'outbox).
///
/// Tient un registre de [PullHandler] par ressource et les exécute :
///  - **pré-garde connectivité** (radio) : hors-ligne → aucun appel ;
///  - **verrou anti-concurrence** (`_pulling`) : un seul cycle *de coordinateur*
///    à la fois. Il ne sérialise **pas** les pulls déclenchés directement sur un
///    repository hors coordinateur (ex. re-pull de réassignation) — sans danger
///    car les upserts sont idempotents (au pire un re-pull redondant) ;
///  - **isolation par ressource** : un handler qui échoue (ou lève) n'empêche
///    pas les autres — l'échec est comptabilisé, pas propagé.
///
/// **Passif** : il est *déclenché* (au retour *online* par `SyncStatusCubit`, ou
/// à la demande), il ne s'abonne pas lui-même à la connectivité — symétrique du
/// `SyncEngine`, piloté par le même point de colle.
class PullCoordinator {
  final ConnectivityService _connectivity;
  final Map<String, PullHandler> _handlers = {};

  bool _pulling = false;

  PullCoordinator({required ConnectivityService connectivity})
    : _connectivity = connectivity;

  /// Enregistre le handler d'une ressource (appelé par la DI des branches).
  void registerHandler(PullHandler handler) {
    _handlers[handler.resource] = handler;
  }

  bool get isPulling => _pulling;

  /// Tire toutes les ressources enregistrées. Ne lève pas : encapsule tout dans
  /// un [PullRunReport].
  Future<PullRunReport> pullAll() async {
    if (_pulling) return const PullRunReport.skipped();
    _pulling = true;
    try {
      if (!await _connectivity.isOnline()) {
        return const PullRunReport.offline();
      }

      var updated = 0, notModified = 0, failed = 0;
      int? latestServerTimeMs;
      for (final handler in _handlers.values) {
        try {
          final outcome = await handler.pull();
          switch (outcome.result) {
            case PullResult.updated:
              updated++;
            case PullResult.notModified:
              notModified++;
            case PullResult.error:
              failed++;
          }
          final observed = outcome.serverTimeMs;
          if (observed != null &&
              (latestServerTimeMs == null || observed > latestServerTimeMs)) {
            latestServerTimeMs = observed;
          }
        } catch (_) {
          // Un handler qui lève (malgré son contrat) est isolé en échec.
          failed++;
        }
      }

      return PullRunReport(
        updated: updated,
        notModified: notModified,
        failed: failed,
        latestServerTimeMs: latestServerTimeMs,
      );
    } finally {
      _pulling = false;
    }
  }
}
