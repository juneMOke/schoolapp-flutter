import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/level_stat.dart';

class LevelStatModel {
  final String id;
  final String code;
  final String label;
  final String cycle;
  final int value;

  const LevelStatModel({
    required this.id,
    required this.code,
    required this.label,
    required this.cycle,
    required this.value,
  });

  factory LevelStatModel.fromJson(Map<String, dynamic> json) {
    return LevelStatModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String,
      label: json['label'] as String? ?? '',
      cycle: json['cycle'] as String? ?? '',
      value: (json['value'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'code': code,
    'label': label,
    'cycle': cycle,
    'value': value,
  };

  LevelStat toEntity() =>
      LevelStat(id: id, code: code, label: label, cycle: cycle, value: value);
}
