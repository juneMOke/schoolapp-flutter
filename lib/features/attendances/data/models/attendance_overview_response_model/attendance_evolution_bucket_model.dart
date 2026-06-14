import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution_bucket.dart';

class AttendanceEvolutionBucketModel {
  final String key;
  final double presenceRate;
  final int recordedDays;
  final bool isCurrent;

  const AttendanceEvolutionBucketModel({
    required this.key,
    required this.presenceRate,
    required this.recordedDays,
    required this.isCurrent,
  });

  factory AttendanceEvolutionBucketModel.fromJson(Map<String, dynamic> json) {
    return AttendanceEvolutionBucketModel(
      key: json['key'] as String,
      presenceRate: (json['presenceRate'] as num).toDouble(),
      recordedDays: (json['recordedDays'] as num).toInt(),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'presenceRate': presenceRate,
    'recordedDays': recordedDays,
    'isCurrent': isCurrent,
  };

  AttendanceEvolutionBucket toEntity() => AttendanceEvolutionBucket(
    key: key,
    presenceRate: presenceRate,
    recordedDays: recordedDays,
    isCurrent: isCurrent,
  );
}
