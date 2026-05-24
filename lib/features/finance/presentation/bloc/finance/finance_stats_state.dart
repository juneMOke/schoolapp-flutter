part of 'finance_stats_bloc.dart';

const _undefined = Object();

enum FinanceStatsStatus { initial, loading, success, error }

enum FinanceStatsErrorType {
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

class FinanceStatsState extends Equatable {
  final FinanceStatsStatus status;
  final FinanceStats? stats;
  final FinanceStatsErrorType errorType;
  final String? errorMessage;
  final FinanceStatsPeriod selectedPeriod;
  final String? selectedMonth;
  final String? selectedWeek;

  const FinanceStatsState({
    this.status = FinanceStatsStatus.initial,
    this.stats,
    this.errorType = FinanceStatsErrorType.none,
    this.errorMessage,
    this.selectedPeriod = FinanceStatsPeriod.year,
    this.selectedMonth,
    this.selectedWeek,
  });

  FinanceStatsState copyWith({
    FinanceStatsStatus? status,
    Object? stats = _undefined,
    FinanceStatsErrorType? errorType,
    Object? errorMessage = _undefined,
    FinanceStatsPeriod? selectedPeriod,
    Object? selectedMonth = _undefined,
    Object? selectedWeek = _undefined,
  }) => FinanceStatsState(
    status: status ?? this.status,
    stats: identical(stats, _undefined) ? this.stats : stats as FinanceStats?,
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
