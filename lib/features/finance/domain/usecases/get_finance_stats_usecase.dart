import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';

class GetFinanceStatsUseCase {
  final FinanceRepository _repository;

  const GetFinanceStatsUseCase(this._repository);

  Future<Either<Failure, FinanceStats>> call({
    FinanceStatsPeriod period = FinanceStatsPeriod.year,
    String? month,
    String? week,
  }) =>
      _repository.getFinanceStats(period: period, month: month, week: week);
}
