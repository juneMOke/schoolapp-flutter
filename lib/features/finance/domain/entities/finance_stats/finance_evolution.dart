import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_evolution_bucket.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_evolution_granularity.dart';

class FinanceEvolution extends Equatable {
  final FinanceEvolutionGranularity granularity;
  final int currentBucketIndex;
  final List<FinanceEvolutionBucket> buckets;

  const FinanceEvolution({
    required this.granularity,
    required this.currentBucketIndex,
    required this.buckets,
  });

  @override
  List<Object?> get props => [granularity, currentBucketIndex, buckets];
}
