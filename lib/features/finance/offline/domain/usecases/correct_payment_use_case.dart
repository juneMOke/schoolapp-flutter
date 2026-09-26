import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';

/// Annule un versement, ou l'annule et le remplace, en un seul geste.
class CorrectPaymentUseCase {
  final PaymentCorrectionRepository _repository;

  const CorrectPaymentUseCase(this._repository);

  Future<Either<Failure, PaymentCorrectionOutcome>> call(
    PaymentCorrectionDraft draft,
  ) => _repository.correctPayment(draft);
}
