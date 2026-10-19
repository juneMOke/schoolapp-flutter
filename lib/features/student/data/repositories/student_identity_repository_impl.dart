import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/data/local/student_identity_dao.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';
import 'package:school_app_flutter/features/student/domain/repositories/student_identity_repository.dart';

class StudentIdentityRepositoryImpl implements StudentIdentityRepository {
  final StudentIdentityDao _dao;

  const StudentIdentityRepositoryImpl(this._dao);

  @override
  Future<Either<Failure, StudentIdentity?>> findIdentity({
    required String studentId,
    required String academicYearId,
  }) async {
    if (studentId.trim().isEmpty) return const Right(null);
    try {
      final row = await _dao.find(
        studentId: studentId,
        academicYearId: academicYearId,
      );
      return Right(row?.toEntity());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
