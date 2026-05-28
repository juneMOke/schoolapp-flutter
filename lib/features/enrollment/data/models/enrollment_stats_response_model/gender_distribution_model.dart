import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/gender_segment_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/gender_distribution.dart';

class GenderDistributionModel {
  final int total;
  final List<GenderSegmentModel> segments;

  const GenderDistributionModel({required this.total, required this.segments});

  factory GenderDistributionModel.fromJson(Map<String, dynamic> json) {
    return GenderDistributionModel(
      total: (json['total'] as num).toInt(),
      segments: (json['segments'] as List<dynamic>)
          .map(
            (item) => GenderSegmentModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'total': total,
    'segments': segments
        .map((segment) => segment.toJson())
        .toList(growable: false),
  };

  GenderDistribution toEntity() => GenderDistribution(
    total: total,
    segments: segments
        .map((segment) => segment.toEntity())
        .toList(growable: false),
  );
}
