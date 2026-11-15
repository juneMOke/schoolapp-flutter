import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';

/// Trésorerie ▸ Tableau de bord, en ligne seulement.
abstract class TreasuryDashboardRepository {
  Future<Either<Failure, TreasuryOverview>> overview();

  /// [from] et [to] ne valent que pour [EvolutionPeriod.custom].
  Future<Either<Failure, TreasuryEvolution>> evolution(
    EvolutionPeriod period, {
    DateTime? from,
    DateTime? to,
  });
}
