import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/level_stat.dart';

class LevelStatModel {
  final String code;
  final int value;

  const LevelStatModel({required this.code, required this.value});

  factory LevelStatModel.fromJson(Map<String, dynamic> json) {
    return LevelStatModel(
      code: json['code'] as String,
      value: (json['value'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'value': value,
  };

  LevelStat toEntity() => LevelStat(code: code, value: value);
}
