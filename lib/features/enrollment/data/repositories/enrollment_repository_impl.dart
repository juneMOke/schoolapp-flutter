import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/data/models/academic_fee_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/paginated_response_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/academic_fee.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/student_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class EnrollmentRepositoryImpl implements EnrollmentRepository {
  final EnrollmentRemoteDataSource remoteDataSource;

  const EnrollmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<StudentSummary>>> getPreRegistrations({
    required String status,
    required String academicYearId,
  }) async {
    try {
      final models = await remoteDataSource.getPreRegistrations(
        status,
        academicYearId,
      );
      return Right(models.map((m) => m.toStudentSummary()).toList());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<StudentSummary>>> searchStudents({
    String? firstName,
    String? lastName,
    String? middleName,
    required String academicYearId,
  }) async {
    try {
      final models = await remoteDataSource.searchStudents(
        firstName,
        lastName,
        middleName,
        academicYearId,
      );
      return Right(models.map((m) => m.toStudentSummary()).toList());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, StudentDetail>> getStudentDetail({
    required String enrollmentId,
  }) async {
    try {
      final model = await remoteDataSource.getStudentDetail(enrollmentId);
      return Right(model.toStudentDetail());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<SchoolLevelGroup>>> getSchoolLevelGroups({
    required String academicYearId,
  }) async {
    try {
      final models =
          await remoteDataSource.getSchoolLevelGroups(academicYearId);
      return Right(models.map((m) => m.toSchoolLevelGroup()).toList());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<SchoolLevel>>> getSchoolLevels({
    required String levelGroupId,
    required String academicYearId,
  }) async {
    try {
      final models = await remoteDataSource.getSchoolLevels(
        levelGroupId,
        academicYearId,
      );
      return Right(models.map((m) => m.toSchoolLevel()).toList());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<AcademicFee>>> getAcademicFees({
    required String levelId,
    required String academicYearId,
    required int page,
    required int size,
  }) async {
    try {
      final data = await remoteDataSource.getAcademicFees(
        levelId,
        academicYearId,
        page,
        size,
      );
      final paginated = PaginatedResponseModel<AcademicFeeModel>.fromJson(
        data,
        AcademicFeeModel.fromJson,
      );
      return Right(
        PaginatedResponse<AcademicFee>(
          content: paginated.content.map((m) => m.toAcademicFee()).toList(),
          totalElements: paginated.totalElements,
          totalPages: paginated.totalPages,
          page: paginated.page,
          size: paginated.size,
        ),
      );
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
