import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/load_staff_file_use_case.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/sync_staff_pulls_use_case.dart';

/// La lecture du fichier du personnel **et ce qui la périme** : un pull qui a
/// écrit l'un des trois flux ou le socle (les pièces exigées), et la fin d'un
/// flush — c'est là qu'un accusé donne son matricule à une fiche créée hors
/// ligne.
class StaffSnapshotSource {
  final LoadStaffFileUseCase _load;
  final SyncStaffPullsUseCase _pulls;
  final PullCompletionBus _bus;
  final SyncEngine _engine;

  const StaffSnapshotSource({
    required LoadStaffFileUseCase load,
    required SyncStaffPullsUseCase pulls,
    required PullCompletionBus bus,
    required SyncEngine engine,
  }) : _load = load,
       _pulls = pulls,
       _bus = bus,
       _engine = engine;

  static final Set<String> watchedResources = {
    ...SyncStaffPullsUseCase.resources,
    ...resourcesOf(SyncPlanKeys.schoolReferential),
  };

  Future<Either<Failure, StaffFileSnapshot>> read() => _load();

  /// Tire les trois flux par le coordinateur (le plan décide lesquels).
  Future<void> pull() => _pulls();

  /// Appelle [onChanged] à chaque signal ; rend la fonction qui désabonne.
  void Function() watch(void Function() onChanged) {
    final subscription = _bus.stream
        .where((resources) => resources.any(watchedResources.contains))
        .listen((_) => onChanged());
    final removeFlushListener = _engine.addFlushCompleteListener(onChanged);
    return () {
      unawaited(subscription.cancel());
      removeFlushListener();
    };
  }
}
