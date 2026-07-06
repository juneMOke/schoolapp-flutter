import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// Pull delta des classes (CF2) : à appeler au démarrage / retour online.
class SyncClassroomsUseCase {
  final ClassroomOfflineRepository _repository;

  const SyncClassroomsUseCase(this._repository);

  Future<Either<Failure, ClassroomSyncOutcome>> call({
    required String academicYearId,
  }) => _repository.syncClassrooms(academicYearId: academicYearId);
}
