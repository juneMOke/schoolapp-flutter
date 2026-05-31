enum EnrollmentStatsPeriod { year, month, week }

extension EnrollmentStatsPeriodX on EnrollmentStatsPeriod {
  String get apiValue => switch (this) {
    EnrollmentStatsPeriod.year => 'year',
    EnrollmentStatsPeriod.month => 'month',
    EnrollmentStatsPeriod.week => 'week',
  };
}
