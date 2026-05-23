import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/gender_segment.dart';

class GenderDistribution extends Equatable {
  final int total;
  final List<GenderSegment> segments;

  const GenderDistribution({required this.total, required this.segments});

  @override
  List<Object?> get props => [total, segments];
}
