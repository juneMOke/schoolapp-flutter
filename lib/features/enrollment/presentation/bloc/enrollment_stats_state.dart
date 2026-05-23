part of 'enrollment_stats_bloc.dart';

const _undefined = Object();

enum EnrollmentStatsStatus { initial, loading, success, error }

enum EnrollmentStatsErrorType {
  none,
  network,
  notFound,
  validation,
  unauthorized,
  invalidCredentials,
  server,
  storage,
  auth,
  unknown,
}

class EnrollmentStatsState extends Equatable {
  final EnrollmentStatsStatus status;
  final EnrollmentStats? stats;
  final EnrollmentStatsErrorType errorType;
  final String? errorMessage;
  final EnrollmentStatsPeriod selectedPeriod;
  final String? selectedMonth;
  final String? selectedWeek;

  const EnrollmentStatsState({
    this.status = EnrollmentStatsStatus.initial,
    this.stats,
    this.errorType = EnrollmentStatsErrorType.none,
    this.errorMessage,
    this.selectedPeriod = EnrollmentStatsPeriod.year,
    this.selectedMonth,
    this.selectedWeek,
  });

  EnrollmentStatsState copyWith({
    EnrollmentStatsStatus? status,
    Object? stats = _undefined,
    EnrollmentStatsErrorType? errorType,
    Object? errorMessage = _undefined,
    EnrollmentStatsPeriod? selectedPeriod,
    Object? selectedMonth = _undefined,
    Object? selectedWeek = _undefined,
  }) => EnrollmentStatsState(
    status: status ?? this.status,
    stats: identical(stats, _undefined) ? this.stats : stats as EnrollmentStats?,
    errorType: errorType ?? this.errorType,
    errorMessage: identical(errorMessage, _undefined)
        ? this.errorMessage
        : errorMessage as String?,
    selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    selectedMonth: identical(selectedMonth, _undefined)
        ? this.selectedMonth
        : selectedMonth as String?,
    selectedWeek: identical(selectedWeek, _undefined)
        ? this.selectedWeek
        : selectedWeek as String?,
  );

  @override
  List<Object?> get props => [
    status,
    stats,
    errorType,
    errorMessage,
    selectedPeriod,
    selectedMonth,
    selectedWeek,
  ];
}
