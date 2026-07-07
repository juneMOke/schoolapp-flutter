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
  final int poisoned;

  const SyncFlushReport({
    this.skipped = false,
    this.offline = false,
    this.acked = 0,
    this.retried = 0,
    this.failed = 0,
    this.noHandler = 0,
    this.poisoned = 0,
  });

  const SyncFlushReport.skipped() : this(skipped: true);
  const SyncFlushReport.offline() : this(offline: true);

  int get processed => acked + retried + failed + noHandler + poisoned;
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
  final int _maxAttempts;
  final Map<String, OutboxSyncHandler> _handlers = {};

  /// Backoff : plafond (5 min) et plancher (1 s).
  static const int _minBackoffMs = 1000;
  static const int _maxBackoffMs = 300000;

  /// Seuil poison-message : au-delà, une entrée en échec transitoire répété
  /// bascule en `SYNC_ERROR` au lieu d'être retentée indéfiniment. L'entrée
  /// poisonnée rejoint l'état **terminal** `SYNC_ERROR` (même sort qu'un rejet
  /// métier, surfacé en `syncConflict`) : pas de reprise automatique, le
  /// recouvrement passe par une ré-écriture (re-enqueue du même id). Défaut
  /// volontairement **haut** : le flush est opportuniste (aucun timer), donc
  /// atteindre le seuil suppose ~50 flushs *en ligne* échoués — improbable pour
  /// une simple coupure transitoire, qui laisse l'entrée en `PENDING`.
  static const int _defaultMaxAttempts = 50;

  bool _flushing = false;

  SyncEngine({
    required OutboxDao outbox,
    required ConnectivityService connectivity,
    Clock now = systemClock,
    int maxAttempts = _defaultMaxAttempts,
  }) : _outbox = outbox,
       _connectivity = connectivity,
       _now = now,
       _maxAttempts = maxAttempts;

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
      var acked = 0, retried = 0, failed = 0, noHandler = 0, poisoned = 0;

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
              if (await _reschedule(entry, result.error)) {
                poisoned++;
              } else {
                retried++;
              }
            case OutboxDispatchOutcome.failed:
              await _outbox.markSyncError(entry.id, result.error);
              failed++;
          }
        } catch (error) {
          // Un handler qui lève est traité comme une erreur transitoire.
          if (await _reschedule(entry, error.toString())) {
            poisoned++;
          } else {
            retried++;
          }
        }
      }

      // Housekeeping : purge des entrées acquittées (leur réconciliation locale
      // a déjà été appliquée par le handler avant markAcked). Best-effort — un
      // échec de purge n'invalide pas le flush.
      try {
        await _outbox.deleteAcked();
      } catch (_) {}

      return SyncFlushReport(
        acked: acked,
        retried: retried,
        failed: failed,
        noHandler: noHandler,
        poisoned: poisoned,
      );
    } finally {
      _flushing = false;
    }
  }

  /// Reprogramme une entrée après une erreur transitoire, ou la **poison**
  /// (bascule `SYNC_ERROR`) si le seuil `_maxAttempts` est franchi. Renvoie
  /// `true` si l'entrée a été poisonnée.
  Future<bool> _reschedule(OutboxEntry entry, String? error) async {
    final attempts = entry.attempts + 1;
    if (attempts > _maxAttempts) {
      await _outbox.markSyncError(
        entry.id,
        'poison: abandon après $attempts tentatives'
        '${error != null ? ' ($error)' : ''}',
      );
      return true;
    }
    await _outbox.reschedule(
      entry.id,
      attempts: attempts,
      nextAttemptAt: _now() + backoffMs(attempts),
      lastError: error,
    );
    return false;
  }

  /// Backoff exponentiel : 2^attempts secondes, borné à [_minBackoffMs,
  /// _maxBackoffMs]. Exposé pour test.
  static int backoffMs(int attempts) {
    final shift = attempts.clamp(0, 8);
    final base = _minBackoffMs * (1 << shift);
    return base.clamp(_minBackoffMs, _maxBackoffMs);
  }
}
