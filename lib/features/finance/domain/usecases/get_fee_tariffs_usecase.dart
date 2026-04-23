import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';

class GetFeeTariffsUseCase {
  final FinanceRepository _repository;

  const GetFeeTariffsUseCase(this._repository);

  Future<Either<Failure, List<FeeTariff>>> call({
    required String levelId,
  }) =>
      _repository.getFeeTariffsByLevel(levelId: levelId);
}
