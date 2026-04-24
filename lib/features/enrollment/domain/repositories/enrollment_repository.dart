import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary_page.dart';

abstract class EnrollmentRepository {
  Future<Either<Failure, EnrollmentSummary>> createEnrollment({
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
    required String birthPlace,
    required String nationality,
    required String gender,
  });

  Future<Either<Failure, EnrollmentSummary>> updateEnrollmentStatus({
    required String enrollmentId,
    required String status,
  });

  Future<Either<Failure, EnrollmentSummaryPage>>
  getEnrollmentSummaryListByStatus({
    required String status,
    required String academicYearId,
    int page = 0,
    int size = AppConstants.enrollmentDefaultPageSize,
  });

  Future<Either<Failure, EnrollmentSummaryPage>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentName({
    required String status,
    required String academicYearId,
    required String firstName,
    required String lastName,
    required String surname,
    int page = 0,
    int size = AppConstants.enrollmentDefaultPageSize,
  });

  Future<Either<Failure, EnrollmentSummaryPage>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirth({
    required String status,
    required String academicYearId,
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
    int page = 0,
    int size = AppConstants.enrollmentDefaultPageSize,
  });

  Future<Either<Failure, EnrollmentSummaryPage>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirth({
    required String status,
    required String academicYearId,
    required String dateOfBirth,
    int page = 0,
    int size = AppConstants.enrollmentDefaultPageSize,
  });

  Future<Either<Failure, EnrollmentSummaryPage>>
  searchEnrollmentSummaryByAcademicInfo({
    required String firstName,
    required String lastName,
    required String surname,
    required String schoolLevelGroupId,
    required String schoolLevelId,
    int page = 0,
    int size = AppConstants.enrollmentDefaultPageSize,
  });

  Future<Either<Failure, EnrollmentDetail>> getEnrollmentDetail({
    required String enrollmentId,
  });

  Future<Either<Failure, EnrollmentDetail>> getEnrollmentPreviewByStudentId({
    required String studentId,
  });
}
