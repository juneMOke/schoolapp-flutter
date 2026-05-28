import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';

class ReassignClassroomMemberUseCase {
  final ClassroomRepository _repository;

  const ReassignClassroomMemberUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String classroomMemberId,
    required String targetClassroomId,
  }) => _repository.reassignClassroomMember(
    classroomMemberId: classroomMemberId,
    targetClassroomId: targetClassroomId,
  );
}
