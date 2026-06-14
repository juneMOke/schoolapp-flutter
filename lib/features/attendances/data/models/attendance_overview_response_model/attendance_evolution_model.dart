import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/attendance_evolution_bucket_model.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution_granularity.dart';

class AttendanceEvolutionModel {
  final String granularity;
  final int currentBucketIndex;
  final List<AttendanceEvolutionBucketModel> buckets;

  const AttendanceEvolutionModel({
    required this.granularity,
    required this.currentBucketIndex,
    this.buckets = const [],
  });

  factory AttendanceEvolutionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceEvolutionModel(
      granularity: json['granularity'] as String,
      currentBucketIndex: (json['currentBucketIndex'] as num).toInt(),
      buckets: (json['buckets'] as List<dynamic>? ?? const [])
          .map(
            (bucket) => AttendanceEvolutionBucketModel.fromJson(
              bucket as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'granularity': granularity,
    'currentBucketIndex': currentBucketIndex,
    'buckets': buckets.map((bucket) => bucket.toJson()).toList(growable: false),
  };

  AttendanceEvolution toEntity() => AttendanceEvolution(
    granularity: AttendanceEvolutionGranularityX.fromApiValue(granularity),
    currentBucketIndex: currentBucketIndex,
    buckets: buckets.map((bucket) => bucket.toEntity()).toList(growable: false),
  );
}
