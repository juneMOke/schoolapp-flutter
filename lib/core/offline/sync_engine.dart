import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';

/// Horloge injectable (epoch ms) — permet un backoff déterministe en test.
typedef Clock = int Function();

int systemClock() => DateTime.now().millisecondsSinceEpoch;

/// Bilan d'un flush (diagnostic / UI).
class SyncFlushReport {
  final bool skipped;
  final bool offline;
  final int acked;
  final int retried;
  final int failed;
  final int noHandler;

  const SyncFlushReport({
    this.skipped = false,
    this.offline = false,
    this.acked = 0,
    this.retried = 0,
    this.failed = 0,
    this.noHandler = 0,
  });

  const SyncFlushReport.skipped() : this(skipped: true);
  const SyncFlushReport.offline() : this(offline: true);

  int get processed => acked + retried + failed + noHandler;
}

/// Moteur de synchro : vide l'outbox en FIFO, route chaque entrée vers le
/// handler de son `aggregateType`, applique un backoff exponentiel sur erreur
/// transitoire, et marque ACKED / SYNC_ERROR selon l'issue.
///
/// Un seul flush à la fois (verrou `_flushing`). Déclenché à la demande et sur
/// chaque passage à « online » (cf. DI).
class SyncEngine {
  final OutboxDao _outbox;
  final ConnectivityService _connectivity;
  final Clock _now;
  final Map<String, OutboxSyncHandler> _handlers = {};

  /// Backoff : plafond (5 min) et plancher (1 s).
  static const int _minBackoffMs = 1000;
  static const int _maxBackoffMs = 300000;

  bool _flushing = false;

  SyncEngine({
    required OutboxDao outbox,
    required ConnectivityService connectivity,
    Clock now = systemClock,
  }) : _outbox = outbox,
       _connectivity = connectivity,
       _now = now;

  /// Enregistre le handler d'un type d'agrégat (appelé par la DI des branches).
  void registerHandler(OutboxSyncHandler handler) {
    _handlers[handler.aggregateType] = handler;
  }

  bool get isFlushing => _flushing;

  /// Vide l'outbox. Ne lève pas : encapsule tout dans un [SyncFlushReport].
  Future<SyncFlushReport> flush({int batchLimit = 50}) async {
    if (_flushing) return const SyncFlushReport.skipped();
    _flushing = true;
    try {
      if (!await _connectivity.isOnline()) {
        return const SyncFlushReport.offline();
      }

      final entries = await _outbox.pendingReady(_now(), limit: batchLimit);
      var acked = 0, retried = 0, failed = 0, noHandler = 0;

      for (final entry in entries) {
        final handler = _handlers[entry.aggregateType];
        if (handler == null) {
          // Aucun handler enregistré : on n'échoue pas l'entrée (une autre
          // branche pourrait l'enregistrer plus tard), on la laisse PENDING.
          noHandler++;
          continue;
        }

        try {
          final result = await handler.dispatch(entry);
          switch (result.outcome) {
            case OutboxDispatchOutcome.acked:
              await _outbox.markAcked(entry.id);
              acked++;
            case OutboxDispatchOutcome.retry:
              await _reschedule(entry, result.error);
              retried++;
            case OutboxDispatchOutcome.failed:
              await _outbox.markSyncError(entry.id, result.error);
              failed++;
          }
        } catch (error) {
          // Un handler qui lève est traité comme une erreur transitoire.
          await _reschedule(entry, error.toString());
          retried++;
        }
      }

      return SyncFlushReport(
        acked: acked,
        retried: retried,
        failed: failed,
        noHandler: noHandler,
      );
    } finally {
      _flushing = false;
    }
  }

  Future<void> _reschedule(OutboxEntry entry, String? error) {
    final attempts = entry.attempts + 1;
    return _outbox.reschedule(
      entry.id,
      attempts: attempts,
      nextAttemptAt: _now() + backoffMs(attempts),
      lastError: error,
    );
  }

  /// Backoff exponentiel : 2^attempts secondes, borné à [_minBackoffMs,
  /// _maxBackoffMs]. Exposé pour test.
  static int backoffMs(int attempts) {
    final shift = attempts.clamp(0, 8);
    final base = _minBackoffMs * (1 << shift);
    return base.clamp(_minBackoffMs, _maxBackoffMs);
  }
}
