import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/cash_register_lock.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/record_payment_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';

/// Annule un versement, ou l'annule et le remplace, en un seul geste.
///
/// Un remplaçant qui fait entrer de l'argent (`cashMoved`) est refusé, sans
/// rien écrire, si la caisse d'une de ses devises est close aujourd'hui (R11).
class CorrectPaymentUseCase {
  final PaymentCorrectionRepository _repository;
  final CashRegisterLock? _lock;

  const CorrectPaymentUseCase(this._repository, {CashRegisterLock? lock})
    : _lock = lock;

  Future<Either<Failure, PaymentCorrectionOutcome>> call(
    PaymentCorrectionDraft draft,
  ) async {
    final replacement = draft.replacement;
    final currencies = draft.cashMoved && replacement != null
        ? cashCurrenciesOf(replacement)
        : const <String>[];
    final guard = await guardCashRegisters(_lock, currencies);
    return guard.fold(
      (failure) async => Left(failure),
      (_) => _repository.correctPayment(draft),
    );
  }
}
