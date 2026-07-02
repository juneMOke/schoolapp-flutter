import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_error_type.dart';

enum TimetableStatus { initial, loading, success, failure }

/// Sentinelle pour distinguer « champ non fourni » de « remis à null » dans
/// [TimetableState.copyWith] (convention projet pour les champs nullable).
const _undefined = Object();

class TimetableState extends Equatable {
  final TimetableStatus status;

  /// Matrice chargée. Peut contenir des cases `null` (créneaux libres) : c'est
  /// normal, **pas** une erreur.
  final WeeklyTimetable? timetable;

  final ScheduleErrorType errorType;

  const TimetableState({
    this.status = TimetableStatus.initial,
    this.timetable,
    this.errorType = ScheduleErrorType.none,
  });

  TimetableState copyWith({
    TimetableStatus? status,
    Object? timetable = _undefined,
    ScheduleErrorType? errorType,
  }) => TimetableState(
    status: status ?? this.status,
    timetable: identical(timetable, _undefined)
        ? this.timetable
        : timetable as WeeklyTimetable?,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, timetable, errorType];
}
