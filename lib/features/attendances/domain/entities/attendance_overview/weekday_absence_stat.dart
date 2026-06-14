import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_weekday.dart';

/// Repartition des absences par jour de la semaine (lundi -> vendredi).
class WeekdayAbsenceStat extends Equatable {
  final AttendanceWeekday weekday;
  final double absenceRate;
  final int recordedDays;

  const WeekdayAbsenceStat({
    required this.weekday,
    required this.absenceRate,
    required this.recordedDays,
  });

  @override
  List<Object?> get props => [weekday, absenceRate, recordedDays];
}
