import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Encaisse un paiement en local-first (retour immédiat, push idempotent).
class RecordPaymentUseCase {
  final FinanceOfflineRepository _repository;

  const RecordPaymentUseCase(this._repository);

  Future<Either<Failure, String>> call(RecordPaymentDraft draft) =>
      _repository.recordPayment(draft);
}
