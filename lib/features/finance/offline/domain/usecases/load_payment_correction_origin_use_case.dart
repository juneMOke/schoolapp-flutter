import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_origin.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';

/// Le versement à corriger, pour pré-remplir son remplaçant.
class LoadPaymentCorrectionOriginUseCase {
  final PaymentCorrectionRepository _repository;

  const LoadPaymentCorrectionOriginUseCase(this._repository);

  Future<Either<Failure, PaymentCorrectionOrigin>> call(String paymentId) =>
      _repository.loadOrigin(paymentId);
}
