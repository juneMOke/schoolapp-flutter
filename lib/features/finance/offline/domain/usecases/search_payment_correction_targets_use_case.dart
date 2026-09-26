import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_target.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';

/// Les élèves vers qui déplacer un versement (D1).
class SearchPaymentCorrectionTargetsUseCase {
  final PaymentCorrectionRepository _repository;

  const SearchPaymentCorrectionTargetsUseCase(this._repository);

  Future<Either<Failure, List<PaymentCorrectionTarget>>> call({
    required String query,
    required String academicYearId,
    required String excludeStudentId,
  }) => _repository.searchTargets(
    query: query,
    academicYearId: academicYearId,
    excludeStudentId: excludeStudentId,
  );
}
