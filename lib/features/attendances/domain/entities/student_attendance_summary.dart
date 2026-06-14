import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';

/// Resume de presence d'un eleve sur une fenetre (annee / mois / semaine).
class StudentAttendanceSummary extends Equatable {
  final String studentId;
  final String firstName;
  final String lastName;
  final String academicYearName;
  final StatsPeriod period;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double presenceRate;
  final int presentDays;
  final int justifiedAbsenceDays;
  final int unjustifiedAbsenceDays;
  final List<StudentAbsenceEntry> absences;

  const StudentAttendanceSummary({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.academicYearName,
    required this.period,
    required this.windowStart,
    required this.windowEnd,
    required this.presenceRate,
    required this.presentDays,
    required this.justifiedAbsenceDays,
    required this.unjustifiedAbsenceDays,
    this.absences = const [],
  });

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    academicYearName,
    period,
    windowStart,
    windowEnd,
    presenceRate,
    presentDays,
    justifiedAbsenceDays,
    unjustifiedAbsenceDays,
    absences,
  ];
}
