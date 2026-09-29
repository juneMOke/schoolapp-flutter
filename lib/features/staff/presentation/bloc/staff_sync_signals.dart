import 'dart:async';

import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/sync_staff_pulls_use_case.dart';

/// Ce qui périme une lecture RH, partagé par le fichier du personnel et le
/// Pointage : un pull qui a écrit l'un des flux lus par l'écran (ou le socle),
/// et la fin d'un flush — c'est là qu'un accusé change l'état d'une ligne.
class StaffSyncSignals {
  final SyncStaffPullsUseCase _pulls;
  final PullCompletionBus _bus;
  final SyncEngine _engine;

  const StaffSyncSignals({
    required SyncStaffPullsUseCase pulls,
    required PullCompletionBus bus,
    required SyncEngine engine,
  }) : _pulls = pulls,
       _bus = bus,
       _engine = engine;

  /// Les flux de l'écran, plus le socle (réglages, pièces exigées, année).
  Set<String> get watchedResources => {
    ..._pulls.watched,
    ...resourcesOf(SyncPlanKeys.schoolReferential),
  };

  /// Tire les flux de l'écran par le coordinateur (le plan décide lesquels).
  Future<void> pull() => _pulls();

  /// Appelle [onChanged] à chaque signal ; rend la fonction qui désabonne.
  void Function() watch(void Function() onChanged) {
    final watched = watchedResources;
    final subscription = _bus.stream
        .where((resources) => resources.any(watched.contains))
        .listen((_) => onChanged());
    final removeFlushListener = _engine.addFlushCompleteListener(onChanged);
    return () {
      unawaited(subscription.cancel());
      removeFlushListener();
    };
  }
}
