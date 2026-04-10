import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/data/datasources/enrollment_academic_info_remote_data_source.dart';
import 'package:school_app_flutter/features/academic_year/data/models/update_enrollment_academic_info_request.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/enrollment_academic_info_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_academic_info_response.dart';

class EnrollmentAcademicInfoRepositoryImpl
    implements EnrollmentAcademicInfoRepository {
  final EnrollmentAcademicInfoRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const EnrollmentAcademicInfoRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, EnrollmentAcademicInfoResponse>> updateEnrollmentAcademicInfo({
    required String enrollmentId,
    required String academicYearId,
    required String previousSchoolName,
    required String previousAcademicYear,
    required String previousSchoolLevelGroup,
    required String previousSchoolLevel,
    required double previousRate,
    int? previousRank,
    required bool validatedPreviousYear,
    String? transferReason,
    String? cancellationReason,
    required String schoolLevelId,
    required String schoolLevelGroupId,
  }) async {
    try {
      final model = await remoteDataSource.updateEnrollmentAcademicInfo(
        requiredAuth,
        enrollmentId,
        UpdateEnrollmentAcademicInfoRequest(
          academicYearId: academicYearId,
          previousSchoolName: previousSchoolName,
          previousAcademicYear: previousAcademicYear,
          previousSchoolLevelGroup: previousSchoolLevelGroup,
          previousSchoolLevel: previousSchoolLevel,
          previousRate: previousRate,
          previousRank: previousRank,
          validatedPreviousYear: validatedPreviousYear,
          transferReason: transferReason,
          cancellationReason: cancellationReason,
          schoolLevelId: schoolLevelId,
          schoolLevelGroupId: schoolLevelGroupId,
        ),
      );
      return Right(model.toEntity());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}

