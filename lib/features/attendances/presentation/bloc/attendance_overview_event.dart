import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';

abstract class AttendanceOverviewEvent extends Equatable {
  const AttendanceOverviewEvent();

  @override
  List<Object?> get props => [];
}

/// Demande le tableau de bord de presence pour une periode.
///
/// [month] (`YYYY-MM`) est requis si [period] == [StatsPeriod.month] ;
/// [week] (`YYYY-Www`) si [period] == [StatsPeriod.week].
class AttendanceOverviewRequested extends AttendanceOverviewEvent {
  final StatsPeriod period;
  final String? month;
  final String? week;

  const AttendanceOverviewRequested({
    this.period = StatsPeriod.year,
    this.month,
    this.week,
  });

  @override
  List<Object?> get props => [period, month, week];
}

/// Recharge le tableau de bord avec la periode courante (bouton "Reessayer").
class AttendanceOverviewRefreshRequested extends AttendanceOverviewEvent {
  const AttendanceOverviewRefreshRequested();
}
