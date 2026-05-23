import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';

class GetClassroomMembersUseCase {
  final ClassroomRepository _repository;

  const GetClassroomMembersUseCase(this._repository);

  Future<Either<Failure, List<ClassroomMember>>> call({
    required String classroomId,
    required String academicYearId,
  }) => _repository.getClassroomMembers(
    classroomId: classroomId,
    academicYearId: academicYearId,
  );
}
