import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/repositories/parent_repository.dart';

class UnlinkParentUseCase {
  final ParentRepository _repository;

  const UnlinkParentUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String studentId,
    required String parentId,
  }) {
    return _repository.unlinkParent(
      studentId: studentId,
      parentId: parentId,
    );
  }
}
