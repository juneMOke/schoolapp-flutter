part of 'finance_stats_bloc.dart';

sealed class FinanceStatsEvent extends Equatable {
  const FinanceStatsEvent();

  @override
  List<Object?> get props => [];
}

class FinanceStatsRequested extends FinanceStatsEvent {
  final FinanceStatsPeriod period;
  final String? month;
  final String? week;

  const FinanceStatsRequested({
    this.period = FinanceStatsPeriod.year,
    this.month,
    this.week,
  });

  @override
  List<Object?> get props => [period, month, week];
}

class FinanceStatsRefreshRequested extends FinanceStatsEvent {
  const FinanceStatsRefreshRequested();
}

class FinanceStatsResetRequested extends FinanceStatsEvent {
  const FinanceStatsResetRequested();
}
