import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution_bucket.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution_granularity.dart';

/// Evolution du taux de presence sur la periode, decoupee en buckets.
///
/// [currentBucketIndex] pointe le bucket courant dans [buckets].
class AttendanceEvolution extends Equatable {
  final AttendanceEvolutionGranularity granularity;
  final int currentBucketIndex;
  final List<AttendanceEvolutionBucket> buckets;

  const AttendanceEvolution({
    required this.granularity,
    required this.currentBucketIndex,
    this.buckets = const [],
  });

  @override
  List<Object?> get props => [granularity, currentBucketIndex, buckets];
}
