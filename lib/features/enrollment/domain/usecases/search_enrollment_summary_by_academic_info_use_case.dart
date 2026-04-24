import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary_page.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class SearchEnrollmentSummaryByAcademicInfoUseCase {
  final EnrollmentRepository _repository;

  const SearchEnrollmentSummaryByAcademicInfoUseCase(this._repository);

  Future<Either<Failure, EnrollmentSummaryPage>> call({
    required String firstName,
    required String lastName,
    required String surname,
    required String schoolLevelGroupId,
    required String schoolLevelId,
    int page = 0,
    int size = AppConstants.enrollmentDefaultPageSize,
  }) {
    return _repository.searchEnrollmentSummaryByAcademicInfo(
      firstName: firstName,
      lastName: lastName,
      surname: surname,
      schoolLevelGroupId: schoolLevelGroupId,
      schoolLevelId: schoolLevelId,
      page: page,
      size: size,
    );
  }
}
