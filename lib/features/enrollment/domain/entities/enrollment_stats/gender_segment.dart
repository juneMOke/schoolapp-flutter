import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/gender_segment_code.dart';

class GenderSegment extends Equatable {
  final GenderSegmentCode code;
  final int value;
  final int percent;

  const GenderSegment({
    required this.code,
    required this.value,
    required this.percent,
  });

  @override
  List<Object?> get props => [code, value, percent];
}
