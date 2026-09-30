import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/load_staff_file_use_case.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/sync_staff_pulls_use_case.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

/// La lecture du fichier du personnel **et ce qui la périme** : un pull qui a
/// écrit l'un des trois flux ou le socle (les pièces exigées), et la fin d'un
/// flush — c'est là qu'un accusé donne son matricule à une fiche créée hors
/// ligne.
class StaffSnapshotSource {
  final LoadStaffFileUseCase _load;
  final StaffSyncSignals _signals;

  StaffSnapshotSource({
    required LoadStaffFileUseCase load,
    required SyncStaffPullsUseCase pulls,
    required PullCompletionBus bus,
    required SyncEngine engine,
  }) : _load = load,
       _signals = StaffSyncSignals(pulls: pulls, bus: bus, engine: engine);

  Set<String> get watchedResources => _signals.watchedResources;

  Future<Either<Failure, StaffFileSnapshot>> read() => _load();

  /// Tire les trois flux par le coordinateur (le plan décide lesquels).
  Future<void> pull() => _signals.pull();

  /// Appelle [onChanged] à chaque signal ; rend la fonction qui désabonne.
  void Function() watch(void Function() onChanged) => _signals.watch(onChanged);
}
