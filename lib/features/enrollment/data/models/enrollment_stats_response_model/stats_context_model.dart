import 'package:school_app_flutter/core/entities/stats_context.dart';

class StatsContextModel {
  final String schoolYear;
  final String period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;

  const StatsContextModel({
    required this.schoolYear,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
  });

  factory StatsContextModel.fromJson(Map<String, dynamic> json) {
    return StatsContextModel(
      schoolYear: json['schoolYear'] as String,
      period: json['period'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schoolYear': schoolYear,
    'period': period,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'generatedAt': generatedAt.toIso8601String(),
  };

  StatsContext toEntity() => StatsContext(
    schoolYear: schoolYear,
    period: period,
    periodStart: periodStart,
    periodEnd: periodEnd,
    generatedAt: generatedAt,
  );
}
