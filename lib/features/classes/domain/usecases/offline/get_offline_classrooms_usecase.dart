import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// Lecture offline des classes + compteurs (CF3), sans charger le roster.
class GetOfflineClassroomsUseCase {
  final ClassroomOfflineRepository _repository;

  const GetOfflineClassroomsUseCase(this._repository);

  Future<Either<Failure, List<OfflineClassroom>>> call({
    required String academicYearId,
    String? schoolLevelId,
  }) => _repository.getClassrooms(
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
  );
}
