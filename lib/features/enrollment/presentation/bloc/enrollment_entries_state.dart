part of 'enrollment_entries_bloc.dart';

const _undefinedField = Object();

enum EnrollmentEntriesStatus { initial, loading, success, empty, error }

class EnrollmentEntriesState extends Equatable {
  final EnrollmentEntriesStatus status;

  /// La fenêtre de la liste — celle dont les lignes sont à l'écran, ou en
  /// cours de chargement. Nulle tant qu'aucune n'a été demandée.
  ///
  /// C'est **elle** que le PDF reprend. Jamais celle d'une lecture
  /// précédente : un changement de fenêtre vide la liste avant de la
  /// recharger.
  final EnrollmentStatsWindow? window;

  final List<DayEnrollmentEntry> entries;

  /// Page courante, **0-based** — celle du serveur. La barre de pagination du
  /// socle, elle, compte à partir de 1 ; la conversion se fait au montage.
  final int page;

  final int totalElements;
  final int totalPages;
  final Failure? failure;

  const EnrollmentEntriesState({
    this.status = EnrollmentEntriesStatus.initial,
    this.window,
    this.entries = const [],
    this.page = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.failure,
  });

  EnrollmentEntriesState copyWith({
    EnrollmentEntriesStatus? status,
    Object? window = _undefinedField,
    List<DayEnrollmentEntry>? entries,
    int? page,
    int? totalElements,
    int? totalPages,
    Object? failure = _undefinedField,
  }) => EnrollmentEntriesState(
    status: status ?? this.status,
    window: identical(window, _undefinedField)
        ? this.window
        : window as EnrollmentStatsWindow?,
    entries: entries ?? this.entries,
    page: page ?? this.page,
    totalElements: totalElements ?? this.totalElements,
    totalPages: totalPages ?? this.totalPages,
    failure: identical(failure, _undefinedField)
        ? this.failure
        : failure as Failure?,
  );

  @override
  List<Object?> get props => [
    status,
    window,
    entries,
    page,
    totalElements,
    totalPages,
    failure,
  ];
}
