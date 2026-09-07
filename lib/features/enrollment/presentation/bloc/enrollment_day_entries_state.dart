part of 'enrollment_day_entries_bloc.dart';

const _undefinedDay = Object();

enum EnrollmentDayEntriesStatus { initial, loading, success, empty, error }

class EnrollmentDayEntriesState extends Equatable {
  final EnrollmentDayEntriesStatus status;

  /// La journée affichée. Nulle tant qu'aucune n'a été demandée.
  final DateTime? day;

  final List<DayEnrollmentEntry> entries;

  /// Page courante, **0-based** — celle du serveur. La barre de pagination du
  /// socle, elle, compte à partir de 1 ; la conversion se fait au montage.
  final int page;

  final int totalElements;
  final int totalPages;
  final Failure? failure;

  const EnrollmentDayEntriesState({
    this.status = EnrollmentDayEntriesStatus.initial,
    this.day,
    this.entries = const [],
    this.page = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.failure,
  });

  EnrollmentDayEntriesState copyWith({
    EnrollmentDayEntriesStatus? status,
    Object? day = _undefinedDay,
    List<DayEnrollmentEntry>? entries,
    int? page,
    int? totalElements,
    int? totalPages,
    Object? failure = _undefinedDay,
  }) => EnrollmentDayEntriesState(
    status: status ?? this.status,
    day: identical(day, _undefinedDay) ? this.day : day as DateTime?,
    entries: entries ?? this.entries,
    page: page ?? this.page,
    totalElements: totalElements ?? this.totalElements,
    totalPages: totalPages ?? this.totalPages,
    failure: identical(failure, _undefinedDay)
        ? this.failure
        : failure as Failure?,
  );

  @override
  List<Object?> get props => [
    status,
    day,
    entries,
    page,
    totalElements,
    totalPages,
    failure,
  ];
}
