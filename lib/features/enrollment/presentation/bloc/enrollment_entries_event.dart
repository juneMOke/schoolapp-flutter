part of 'enrollment_entries_bloc.dart';

sealed class EnrollmentEntriesEvent extends Equatable {
  const EnrollmentEntriesEvent();

  @override
  List<Object?> get props => [];
}

/// Charge la première page d'une fenêtre.
///
/// La fenêtre vient de l'agrégat, jamais d'ici : cette liste ne choisit pas ce
/// qu'elle montre.
class EnrollmentEntriesRequested extends EnrollmentEntriesEvent {
  final EnrollmentStatsWindow window;

  const EnrollmentEntriesRequested(this.window);

  @override
  List<Object?> get props => [window];
}

/// Tourne la page — **0-based**, comme le serveur.
class EnrollmentEntriesPageChanged extends EnrollmentEntriesEvent {
  final int page;

  const EnrollmentEntriesPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

/// Vide la liste — l'agrégat n'a rien de juste à montrer.
class EnrollmentEntriesCleared extends EnrollmentEntriesEvent {
  const EnrollmentEntriesCleared();
}
