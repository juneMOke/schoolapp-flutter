import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/top_absent_class.dart';

class TopAbsentClassModel {
  final String classroomId;
  final String className;
  final String level;
  final double absenceRate;
  final int absenceDays;

  const TopAbsentClassModel({
    required this.classroomId,
    required this.className,
    required this.level,
    required this.absenceRate,
    required this.absenceDays,
  });

  factory TopAbsentClassModel.fromJson(Map<String, dynamic> json) {
    return TopAbsentClassModel(
      classroomId: json['classroomId'] as String,
      className: json['className'] as String,
      level: json['level'] as String,
      absenceRate: (json['absenceRate'] as num).toDouble(),
      absenceDays: (json['absenceDays'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'classroomId': classroomId,
    'className': className,
    'level': level,
    'absenceRate': absenceRate,
    'absenceDays': absenceDays,
  };

  TopAbsentClass toEntity() => TopAbsentClass(
    classroomId: classroomId,
    className: className,
    level: level,
    absenceRate: absenceRate,
    absenceDays: absenceDays,
  );
}
