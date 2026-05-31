import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/fee_type_distribution.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_evolution.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_kpis.dart';

class FinanceStats extends Equatable {
  final StatsContext context;
  final FinanceKpis kpis;
  final FinanceEvolution evolution;
  final FeeTypeDistribution distributionByFeeType;

  const FinanceStats({
    required this.context,
    required this.kpis,
    required this.evolution,
    required this.distributionByFeeType,
  });

  @override
  List<Object?> get props => [context, kpis, evolution, distributionByFeeType];
}
