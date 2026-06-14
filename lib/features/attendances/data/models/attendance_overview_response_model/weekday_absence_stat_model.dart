import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_weekday.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/weekday_absence_stat.dart';

class WeekdayAbsenceStatModel {
  final String weekday;
  final double absenceRate;
  final int recordedDays;

  const WeekdayAbsenceStatModel({
    required this.weekday,
    required this.absenceRate,
    required this.recordedDays,
  });

  factory WeekdayAbsenceStatModel.fromJson(Map<String, dynamic> json) {
    return WeekdayAbsenceStatModel(
      weekday: json['weekday'] as String,
      absenceRate: (json['absenceRate'] as num).toDouble(),
      recordedDays: (json['recordedDays'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'weekday': weekday,
    'absenceRate': absenceRate,
    'recordedDays': recordedDays,
  };

  WeekdayAbsenceStat toEntity() => WeekdayAbsenceStat(
    weekday: AttendanceWeekdayX.fromApiValue(weekday),
    absenceRate: absenceRate,
    recordedDays: recordedDays,
  );
}
