import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_kpis.dart';

class AttendanceKpisModel {
  final double presenceRate;
  final double justifiedAbsenceRate;
  final double unjustifiedAbsenceRate;
  final int recordedDays;
  final int presentDays;
  final int justifiedAbsenceDays;
  final int unjustifiedAbsenceDays;

  const AttendanceKpisModel({
    required this.presenceRate,
    required this.justifiedAbsenceRate,
    required this.unjustifiedAbsenceRate,
    required this.recordedDays,
    required this.presentDays,
    required this.justifiedAbsenceDays,
    required this.unjustifiedAbsenceDays,
  });

  factory AttendanceKpisModel.fromJson(Map<String, dynamic> json) {
    return AttendanceKpisModel(
      presenceRate: (json['presenceRate'] as num).toDouble(),
      justifiedAbsenceRate: (json['justifiedAbsenceRate'] as num).toDouble(),
      unjustifiedAbsenceRate: (json['unjustifiedAbsenceRate'] as num)
          .toDouble(),
      recordedDays: (json['recordedDays'] as num).toInt(),
      presentDays: (json['presentDays'] as num).toInt(),
      justifiedAbsenceDays: (json['justifiedAbsenceDays'] as num).toInt(),
      unjustifiedAbsenceDays: (json['unjustifiedAbsenceDays'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'presenceRate': presenceRate,
    'justifiedAbsenceRate': justifiedAbsenceRate,
    'unjustifiedAbsenceRate': unjustifiedAbsenceRate,
    'recordedDays': recordedDays,
    'presentDays': presentDays,
    'justifiedAbsenceDays': justifiedAbsenceDays,
    'unjustifiedAbsenceDays': unjustifiedAbsenceDays,
  };

  AttendanceKpis toEntity() => AttendanceKpis(
    presenceRate: presenceRate,
    justifiedAbsenceRate: justifiedAbsenceRate,
    unjustifiedAbsenceRate: unjustifiedAbsenceRate,
    recordedDays: recordedDays,
    presentDays: presentDays,
    justifiedAbsenceDays: justifiedAbsenceDays,
    unjustifiedAbsenceDays: unjustifiedAbsenceDays,
  );
}
