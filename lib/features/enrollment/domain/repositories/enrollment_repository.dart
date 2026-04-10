import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';

abstract class EnrollmentRepository {
  Future<Either<Failure, List<EnrollmentSummary>>>
  getEnrollmentSummaryListByStatus({
    required String status,
    required String academicYearId,
  });

  Future<Either<Failure, List<EnrollmentSummary>>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentName({
    required String status,
    required String academicYearId,
    required String firstName,
    required String lastName,
    required String surname,
  });

  Future<Either<Failure, List<EnrollmentSummary>>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirth({
    required String status,
    required String academicYearId,
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
  });

  Future<Either<Failure, List<EnrollmentSummary>>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirth({
    required String status,
    required String academicYearId,
    required String dateOfBirth,
  });

  Future<Either<Failure, List<EnrollmentSummary>>>
  searchEnrollmentSummaryByAcademicInfo({
    required String firstName,
    required String lastName,
    required String surname,
    required String schoolLevelGroupId,
    required String schoolLevelId,
  });

  Future<Either<Failure, EnrollmentDetail>> getEnrollmentDetail({
    required String enrollmentId,
  });
}
