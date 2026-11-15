import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/cash_register_lock.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Encaisse un paiement en local-first (retour immédiat, push idempotent).
///
/// Refusé, sans rien écrire, si la caisse d'une devise perçue est close
/// aujourd'hui (R11) : [CashRegisterClosedFailure].
class RecordPaymentUseCase {
  final FinanceOfflineRepository _repository;
  final CashRegisterLock? _lock;

  const RecordPaymentUseCase(this._repository, {CashRegisterLock? lock})
    : _lock = lock;

  Future<Either<Failure, String>> call(RecordPaymentDraft draft) async {
    final guard = await guardCashRegisters(_lock, cashCurrenciesOf(draft));
    return guard.fold(
      (failure) async => Left(failure),
      (_) => _repository.recordPayment(draft),
    );
  }
}

/// Les devises qu'un versement fait entrer dans le tiroir : ses lignes de
/// perçu, à défaut ses montants, à défaut ses imputations. Rien pour un versement qui n'est pas en
/// espèces.
Iterable<String> cashCurrenciesOf(RecordPaymentDraft draft) {
  final method = PaymentMethod.fromApiValue(draft.method);
  if (method != PaymentMethod.cash) return const [];
  final tenders = draft.tenders;
  if (tenders != null && tenders.isNotEmpty) {
    return {
      for (final t in tenders)
        if (t.amountInCents > 0) t.currency,
    };
  }
  final amounts = draft.amounts;
  if (amounts != null && amounts.isNotEmpty) {
    return {for (final m in amounts.entries) m.currency};
  }
  // Ni perçu ni montants : le dépôt dérive le perçu des imputations.
  return {for (final a in draft.allocations) a.currency};
}
