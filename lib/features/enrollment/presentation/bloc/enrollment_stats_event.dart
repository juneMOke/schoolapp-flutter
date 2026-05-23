part of 'enrollment_stats_bloc.dart';

sealed class EnrollmentStatsEvent extends Equatable {
  const EnrollmentStatsEvent();

  @override
  List<Object?> get props => [];
}

class EnrollmentStatsRequested extends EnrollmentStatsEvent {
  final EnrollmentStatsPeriod period;
  final String? month;
  final String? week;

  const EnrollmentStatsRequested({
    this.period = EnrollmentStatsPeriod.year,
    this.month,
    this.week,
  });

  @override
  List<Object?> get props => [period, month, week];
}

class EnrollmentStatsRefreshRequested extends EnrollmentStatsEvent {
  const EnrollmentStatsRefreshRequested();
}

class EnrollmentStatsResetRequested extends EnrollmentStatsEvent {
  const EnrollmentStatsResetRequested();
}
