import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/gender_segment.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/gender_segment_code.dart';

class GenderSegmentModel {
  final String code;
  final int value;
  final int percent;

  const GenderSegmentModel({
    required this.code,
    required this.value,
    required this.percent,
  });

  factory GenderSegmentModel.fromJson(Map<String, dynamic> json) {
    return GenderSegmentModel(
      code: json['code'] as String,
      value: (json['value'] as num).toInt(),
      percent: (json['percent'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'value': value,
    'percent': percent,
  };

  GenderSegment toEntity() => GenderSegment(
    code: _parseCode(code),
    value: value,
    percent: percent,
  );

  GenderSegmentCode _parseCode(String value) => switch (value) {
    'MALE' => GenderSegmentCode.male,
    'FEMALE' => GenderSegmentCode.female,
    _ => GenderSegmentCode.other,
  };
}
