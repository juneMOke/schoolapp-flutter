import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/online/treasury_dashboard_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_online.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_dashboard_repository.dart';

class TreasuryDashboardRepositoryImpl implements TreasuryDashboardRepository {
  final TreasuryDashboardApi _api;

  const TreasuryDashboardRepositoryImpl(this._api);

  @override
  Future<Either<Failure, TreasuryOverview>> overview() =>
      guardTreasury(_api.overview);

  @override
  Future<Either<Failure, TreasuryEvolution>> evolution(
    EvolutionPeriod period, {
    DateTime? from,
    DateTime? to,
  }) => guardTreasury(() => _api.evolution(period, from: from, to: to));
}
