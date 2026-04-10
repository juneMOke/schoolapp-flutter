import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_academic_info_response.dart';

abstract class EnrollmentAcademicInfoRepository {
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
  });
}
