import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';

abstract class StudentAttendanceSummaryEvent extends Equatable {
  const StudentAttendanceSummaryEvent();

  @override
  List<Object?> get props => [];
}

/// Demande le resume de presence d'un eleve sur une fenetre.
///
/// [month] (`YYYY-MM`) est requis si [period] == [StatsPeriod.month] ;
/// [week] (`YYYY-MM-DD`) si [period] == [StatsPeriod.week].
class StudentAttendanceSummaryRequested extends StudentAttendanceSummaryEvent {
  final String studentId;
  final StatsPeriod period;
  final String? month;
  final String? week;

  const StudentAttendanceSummaryRequested({
    required this.studentId,
    this.period = StatsPeriod.year,
    this.month,
    this.week,
  });

  @override
  List<Object?> get props => [studentId, period, month, week];
}
