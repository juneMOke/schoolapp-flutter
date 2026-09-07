part of 'enrollment_stats_bloc.dart';

sealed class EnrollmentStatsEvent extends Equatable {
  const EnrollmentStatsEvent();

  @override
  List<Object?> get props => [];
}

/// Demande les chiffres d'une fenêtre.
///
/// C'est le SEUL évènement qui change de fenêtre : il n'y a pas d'évènement
/// « changer d'onglet » séparé. Choisir une fenêtre et demander ses chiffres
/// sont le même geste, et les séparer laisserait exister un état où l'onglet
/// affiché ne correspond plus aux chiffres affichés.
class EnrollmentStatsRequested extends EnrollmentStatsEvent {
  final EnrollmentStatsWindow window;

  const EnrollmentStatsRequested({
    this.window = const EnrollmentStatsWindow.year(),
  });

  @override
  List<Object?> get props => [window];
}

/// Rejoue la fenêtre courante — la reprise après un échec.
class EnrollmentStatsRefreshRequested extends EnrollmentStatsEvent {
  const EnrollmentStatsRefreshRequested();
}

class EnrollmentStatsResetRequested extends EnrollmentStatsEvent {
  const EnrollmentStatsResetRequested();
}
