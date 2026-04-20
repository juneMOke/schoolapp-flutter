import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';

abstract class ParentRepository {
  Future<Either<Failure, ParentSummary>> updateParent({
    required String parentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String email,
    required String phoneNumber,
    required String relationshipType,
  });

  Future<Either<Failure, ParentSummary>> createParent({
    required String studentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String phoneNumber,
    required String relationshipType,
  });
}
