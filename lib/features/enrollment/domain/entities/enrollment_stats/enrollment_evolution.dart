import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/evolution_bucket.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/evolution_granularity.dart';

class EnrollmentEvolution extends Equatable {
  final EvolutionGranularity granularity;
  final int currentBucketIndex;
  final List<EvolutionBucket> buckets;

  const EnrollmentEvolution({
    required this.granularity,
    required this.currentBucketIndex,
    required this.buckets,
  });

  @override
  List<Object?> get props => [granularity, currentBucketIndex, buckets];
}
