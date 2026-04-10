import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/enrollment_academic_info_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_academic_info_response.dart';

class UpdateEnrollmentAcademicInfoUseCase {
  final EnrollmentAcademicInfoRepository _repository;

  const UpdateEnrollmentAcademicInfoUseCase(this._repository);

  Future<Either<Failure, EnrollmentAcademicInfoResponse>> call({
    required String studentId,
    required String academicYearId,
    required String previousSchoolName,
    required String previousAcademicYear,
    required String previousSchoolLevelGroup,
    required String previousSchoolLevel,
    required double previousRate,
    int? previousRank,
    required bool validatedPreviousYear,
    String? transferReason,
    String? cancellationReason
  }) {
    return _repository.updateEnrollmentAcademicInfo(
      enrollmentId: studentId,
      academicYearId: academicYearId,
      previousSchoolName: previousSchoolName,
      previousAcademicYear: previousAcademicYear,
      previousSchoolLevelGroup: previousSchoolLevelGroup,
      previousSchoolLevel: previousSchoolLevel,
      previousRate: previousRate,
      previousRank: previousRank,
      validatedPreviousYear: validatedPreviousYear,
      transferReason: transferReason,
      cancellationReason: cancellationReason
    );
  }
}
