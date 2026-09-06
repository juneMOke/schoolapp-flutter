part of 'enrollment_day_entries_bloc.dart';

sealed class EnrollmentDayEntriesEvent extends Equatable {
  const EnrollmentDayEntriesEvent();

  @override
  List<Object?> get props => [];
}

/// Charge la première page d'une journée.
///
/// Le jour vient de la fenêtre de l'agrégat, jamais d'ici : cette liste ne
/// choisit pas ce qu'elle montre.
class EnrollmentDayEntriesRequested extends EnrollmentDayEntriesEvent {
  final DateTime day;

  const EnrollmentDayEntriesRequested(this.day);

  @override
  List<Object?> get props => [day];
}

class EnrollmentDayEntriesPageChanged extends EnrollmentDayEntriesEvent {
  final int page;

  const EnrollmentDayEntriesPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

/// Vide la liste — la fenêtre a cessé d'être une journée.
class EnrollmentDayEntriesCleared extends EnrollmentDayEntriesEvent {
  const EnrollmentDayEntriesCleared();
}
