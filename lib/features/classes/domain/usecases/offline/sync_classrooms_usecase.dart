import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// Pull delta des classes (CF2) : à appeler au démarrage / retour online.
///
/// **Gate connectivité** : déclenché sans garde au montage de l'écran Classes
/// — sans `ConnectivityService`, une tablette hors-ligne taperait quand même
/// le réseau à chaque montage (même raisonnement que `SyncFinancePullsUseCase`
/// / `SyncAcademicsPullsUseCase`).
class SyncClassroomsUseCase {
  final ClassroomOfflineRepository _repository;
  final ConnectivityService _connectivity;

  const SyncClassroomsUseCase(this._repository, this._connectivity);

  Future<Either<Failure, ClassroomSyncOutcome>> call({
    required String academicYearId,
  }) async {
    if (!await _connectivity.isOnline()) {
      return const Left(NetworkFailure('Offline: classrooms sync skipped'));
    }
    return _repository.syncClassrooms(academicYearId: academicYearId);
  }
}
