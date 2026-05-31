import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/level_stat_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/cycle_stat.dart';

class CycleStatModel {
  final String code;
  final int total;
  final List<LevelStatModel> levels;

  const CycleStatModel({
    required this.code,
    required this.total,
    required this.levels,
  });

  factory CycleStatModel.fromJson(Map<String, dynamic> json) {
    return CycleStatModel(
      code: json['code'] as String,
      total: (json['total'] as num).toInt(),
      levels: (json['levels'] as List<dynamic>)
          .map((item) => LevelStatModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'total': total,
    'levels': levels.map((level) => level.toJson()).toList(growable: false),
  };

  CycleStat toEntity() => CycleStat(
    code: code,
    total: total,
    levels: levels.map((level) => level.toEntity()).toList(growable: false),
  );
}
