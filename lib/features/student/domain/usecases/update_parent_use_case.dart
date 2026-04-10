import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/repositories/parent_repository.dart';

class UpdateParentUseCase {
  final ParentRepository _repository;

  const UpdateParentUseCase(this._repository);

  Future<Either<Failure, ParentSummary>> call({
    required String parentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String email,
    required String phoneNumber,
    required String relationshipType,
  }) {
    return _repository.updateParent(
      parentId: parentId,
      firstName: firstName,
      lastName: lastName,
      surname: surname,
      email: email,
      phoneNumber: phoneNumber,
      relationshipType: relationshipType,
    );
  }
}
