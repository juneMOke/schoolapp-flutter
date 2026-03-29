import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/academic_fee.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetAcademicFeesUseCase {
  final EnrollmentRepository _repository;

  const GetAcademicFeesUseCase(this._repository);

  Future<Either<Failure, PaginatedResponse<AcademicFee>>> call({
    required String levelId,
    required String academicYearId,
    required int page,
    required int size,
  }) {
    return _repository.getAcademicFees(
      levelId: levelId,
      academicYearId: academicYearId,
      page: page,
      size: size,
    );
  }
}
