import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/data/models/create_enrollment_request_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class EnrollmentRepositoryImpl implements EnrollmentRepository {
  final EnrollmentRemoteDataSource remoteDataSource;

  final Map<String, dynamic> requiredAuth;

  const EnrollmentRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, EnrollmentSummary>> createEnrollment({
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
    required String birthPlace,
    required String nationality,
    required String gender,
  }) async {
    try {
      final enrollmentSummaryModel = await remoteDataSource.createEnrollment(
        requiredAuth,
        CreateEnrollmentRequestModel(
          firstName: firstName,
          lastName: lastName,
          surname: surname,
          dateOfBirth: dateOfBirth,
          birthPlace: birthPlace,
          nationality: nationality,
          gender: gender,
        ),
      );
      return Right(enrollmentSummaryModel.toEnrollmentSummary());
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
  Future<Either<Failure, List<EnrollmentSummary>>>
  getEnrollmentSummaryListByStatus({
    required String status,
    required String academicYearId,
  }) async {
    try {
      final enrollmentModelList = await remoteDataSource
          .getEnrollmentSummaryByStatusAndAcademicYear(
            requiredAuth,
            status,
            academicYearId,
          );
      return Right(
        enrollmentModelList.map((m) => m.toEnrollmentSummary()).toList(),
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

  @override
  Future<Either<Failure, List<EnrollmentSummary>>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentName({
    required String status,
    required String academicYearId,
    required String firstName,
    required String lastName,
    required String surname,
  }) async {
    try {
      final enrollmentModelList = await remoteDataSource
          .searchEnrollmentSummaryByStatusAndAcademicYearAndStudentName(
            requiredAuth,
            status,
            academicYearId,
            firstName,
            lastName,
            surname,
          );
      return Right(
        enrollmentModelList.map((m) => m.toEnrollmentSummary()).toList(),
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

  @override
  Future<Either<Failure, List<EnrollmentSummary>>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirth({
    required String status,
    required String academicYearId,
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
  }) async {
    try {
      final enrollmentModelList = await remoteDataSource
          .searchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirth(
            requiredAuth,
            status,
            academicYearId,
            firstName,
            lastName,
            surname,
            dateOfBirth,
          );
      return Right(
        enrollmentModelList.map((m) => m.toEnrollmentSummary()).toList(),
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

  @override
  Future<Either<Failure, List<EnrollmentSummary>>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirth({
    required String status,
    required String academicYearId,
    required String dateOfBirth,
  }) async {
    try {
      final enrollmentModelList = await remoteDataSource
          .searchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirth(
            requiredAuth,
            status,
            academicYearId,
            dateOfBirth,
          );
      return Right(
        enrollmentModelList.map((m) => m.toEnrollmentSummary()).toList(),
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

  @override
  Future<Either<Failure, List<EnrollmentSummary>>>
  searchEnrollmentSummaryByAcademicInfo({
    required String firstName,
    required String lastName,
    required String surname,
    required String schoolLevelGroupId,
    required String schoolLevelId,
  }) async {
    try {
      final enrollmentModelList = await remoteDataSource
          .searchEnrollmentSummaryByAcademicInfo(
            requiredAuth,
            firstName,
            lastName,
            surname,
            schoolLevelGroupId,
            schoolLevelId,
          );
      return Right(
        enrollmentModelList.map((m) => m.toEnrollmentSummary()).toList(),
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

  @override
  Future<Either<Failure, EnrollmentDetail>> getEnrollmentDetail({
    required String enrollmentId,
  }) async {
    try {
      final enrollmentModel = await remoteDataSource.getEnrollmentDetail(
        requiredAuth,
        enrollmentId,
      );
      return Right(enrollmentModel.toEnrollmentDetail());
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
  Future<Either<Failure, EnrollmentDetail>> getEnrollmentPreviewByStudentId({
    required String studentId,
  }) async {
    try {
      final enrollmentModel = await remoteDataSource
          .getEnrollmentPreviewByStudentId(requiredAuth, studentId);
      return Right(enrollmentModel.toEnrollmentDetail());
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
