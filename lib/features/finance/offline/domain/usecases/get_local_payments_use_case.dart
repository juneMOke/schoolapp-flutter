import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Historique de paiements local d'un élève.
class GetLocalPaymentsUseCase {
  final FinanceOfflineRepository _repository;

  const GetLocalPaymentsUseCase(this._repository);

  Future<Either<Failure, List<LocalPayment>>> call(String studentId) =>
      _repository.getPayments(studentId);
}
