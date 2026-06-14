import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/class_attendance_stat.dart';

class ClassAttendanceStatModel {
  final String cycle;
  final String level;
  final String classroomId;
  final String className;
  final double presenceRate;
  final double justifiedAbsenceRate;
  final double unjustifiedAbsenceRate;
  final int recordedDays;

  const ClassAttendanceStatModel({
    required this.cycle,
    required this.level,
    required this.classroomId,
    required this.className,
    required this.presenceRate,
    required this.justifiedAbsenceRate,
    required this.unjustifiedAbsenceRate,
    required this.recordedDays,
  });

  factory ClassAttendanceStatModel.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceStatModel(
      cycle: json['cycle'] as String,
      level: json['level'] as String,
      classroomId: json['classroomId'] as String,
      className: json['className'] as String,
      presenceRate: (json['presenceRate'] as num).toDouble(),
      justifiedAbsenceRate: (json['justifiedAbsenceRate'] as num).toDouble(),
      unjustifiedAbsenceRate: (json['unjustifiedAbsenceRate'] as num)
          .toDouble(),
      recordedDays: (json['recordedDays'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'cycle': cycle,
    'level': level,
    'classroomId': classroomId,
    'className': className,
    'presenceRate': presenceRate,
    'justifiedAbsenceRate': justifiedAbsenceRate,
    'unjustifiedAbsenceRate': unjustifiedAbsenceRate,
    'recordedDays': recordedDays,
  };

  ClassAttendanceStat toEntity() => ClassAttendanceStat(
    cycle: cycle,
    level: level,
    classroomId: classroomId,
    className: className,
    presenceRate: presenceRate,
    justifiedAbsenceRate: justifiedAbsenceRate,
    unjustifiedAbsenceRate: unjustifiedAbsenceRate,
    recordedDays: recordedDays,
  );
}
