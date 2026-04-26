import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';

class GetClassroomsUseCase {
  final ClassroomRepository _repository;

  const GetClassroomsUseCase(this._repository);

  Future<Either<Failure, List<Classroom>>> call({
    required String schoolLevelGroupId,
    required String schoolLevelId,
    required String academicYearId,
  }) => _repository.getClassroomsByLevelAndAcademicYear(
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
    academicYearId: academicYearId,
  );
}
