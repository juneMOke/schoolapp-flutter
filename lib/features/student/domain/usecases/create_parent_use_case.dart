import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/repositories/parent_repository.dart';

class CreateParentUseCase {
  final ParentRepository _repository;

  const CreateParentUseCase(this._repository);

  Future<Either<Failure, ParentSummary>> call({
    required String studentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String phoneNumber,
    required String relationshipType,
  }) =>
      _repository.createParent(
        studentId: studentId,
        firstName: firstName,
        lastName: lastName,
        surname: surname,
        phoneNumber: phoneNumber,
        relationshipType: relationshipType,
      );
}
