enum FinanceStatsPeriod { year, month, week }

extension FinanceStatsPeriodX on FinanceStatsPeriod {
  String get apiValue => switch (this) {
    FinanceStatsPeriod.year => 'year',
    FinanceStatsPeriod.month => 'month',
    FinanceStatsPeriod.week => 'week',
  };
}
