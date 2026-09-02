import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// La série de taux de guichet de l'école, lue en local.
class GetExchangeRatesUseCase {
  final FinanceOfflineRepository _repository;

  const GetExchangeRatesUseCase(this._repository);

  Future<Either<Failure, List<ExchangeRate>>> call() =>
      _repository.getExchangeRates();
}
