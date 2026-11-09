import 'dart:async';

import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/enrollment_level_correction/data/level_correction_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_sync_dao.dart';

/// Tire un sous-ensemble de ressources — `PullCoordinator.pullSubset`.
typedef LevelCorrectionPull =
    Future<PullRunReport> Function(Set<String> resources);

/// Fait descendre ce qu'une correction accusée a changé au serveur, et ne la
/// dit **descendue** (`settled_at`) que sur preuve.
///
/// La preuve : une descente partie **après** l'accusé, où chacune des
/// ressources [required] a été tentée sans échec. Le coordinateur isole les
/// échecs par ressource — l'inscription peut descendre et les créances non —,
/// et c'est sur les créances que la caisse encaisse : tant qu'elles ne sont pas
/// là, la garde du guichet tient.
///
/// Une passe **par fin de flush**, jamais une par accusé : N corrections
/// accusées au retour du réseau partagent la même descente. Tant qu'une
/// correction reste à descendre (hors ligne, flux en échec), chaque flush
/// suivant retente.
class LevelCorrectionSettler {
  final LevelCorrectionSyncDao _sync;
  final LevelCorrectionChangeBus _bus;
  final LevelCorrectionPull _pull;

  /// Ce qui est tiré.
  final Set<String> resources;

  /// Ce qui doit être passé pour que la correction soit dite descendue.
  final Set<String> required;
  final Clock _now;

  Future<void>? _running;

  LevelCorrectionSettler({
    required LevelCorrectionSyncDao sync,
    required LevelCorrectionChangeBus bus,
    required LevelCorrectionPull pull,
    required this.resources,
    required this.required,
    Clock now = systemClock,
  }) : _sync = sync,
       _bus = bus,
       _pull = pull,
       _now = now;

  /// Une passe ; celle déjà en vol si elle n'est pas finie. Ne lève pas.
  Future<void> settle() => _running ??= _settle().whenComplete(() {
    _running = null;
  });

  Future<void> _settle() async {
    try {
      if (!await _sync.hasUnsettled()) return;
      final pulledFromMs = _now();
      final report = await _pull(resources);
      if (!required.every(report.succeeded)) return;
      final settled = await _sync.markSettled(
        pulledFromMs: pulledFromMs,
        nowMs: _now(),
      );
      if (settled.isNotEmpty) _bus.emit(settled);
    } catch (_) {
      // Retenté au prochain flush : la garde tient d'ici là.
    }
  }
}
