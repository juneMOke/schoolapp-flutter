import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_overview.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';

enum AttendanceOverviewStatus { initial, loading, success, failure }

const _undefined = Object();

class AttendanceOverviewState extends Equatable {
  final AttendanceOverviewStatus status;
  final AttendanceOverview? overview;

  /// Reutilise le type d'erreur partage du module (meme anatomie 4 types).
  final AttendanceErrorType errorType;

  /// Periode active, conservee pour le rechargement et le filtre.
  final StatsPeriod selectedPeriod;
  final String? selectedMonth;
  final String? selectedWeek;

  const AttendanceOverviewState({
    this.status = AttendanceOverviewStatus.initial,
    this.overview,
    this.errorType = AttendanceErrorType.none,
    this.selectedPeriod = StatsPeriod.year,
    this.selectedMonth,
    this.selectedWeek,
  });

  AttendanceOverviewState copyWith({
    AttendanceOverviewStatus? status,
    Object? overview = _undefined,
    AttendanceErrorType? errorType,
    StatsPeriod? selectedPeriod,
    Object? selectedMonth = _undefined,
    Object? selectedWeek = _undefined,
  }) => AttendanceOverviewState(
    status: status ?? this.status,
    overview: identical(overview, _undefined)
        ? this.overview
        : overview as AttendanceOverview?,
    errorType: errorType ?? this.errorType,
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
    overview,
    errorType,
    selectedPeriod,
    selectedMonth,
    selectedWeek,
  ];
}
