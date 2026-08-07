import 'package:equatable/equatable.dart';

sealed class TimetableEvent extends Equatable {
  const TimetableEvent();
}

/// Demande l'emploi du temps de l'enseignant connecté pour [academicYearId].
///
/// L'[academicYearId] est fourni par l'appelant (ex. depuis l'année courante du
/// `BootstrapBloc`) — le module `schedule` ne dépend pas directement du
/// bootstrap.
class TimetableRequested extends TimetableEvent {
  final String academicYearId;

  const TimetableRequested({required this.academicYearId});

  @override
  List<Object?> get props => [academicYearId];
}

/// Relit **silencieusement** l'emploi du temps déjà demandé, sans repasser par
/// un état de chargement.
///
/// Émis quand un pull vient de rafraîchir le cache local ([PullCompletionBus]) :
/// l'écran a lu le local bien avant la réponse réseau, il faut le relire sans
/// faire clignoter le squelette ni transformer une grille affichée en écran
/// d'erreur si la relecture échoue. Sans effet tant qu'aucun
/// [TimetableRequested] n'a fixé l'année, et après un [ClassroomGridRequested]
/// (l'écran affiche alors la grille d'une classe, pas mon emploi du temps).
class TimetableRefreshRequested extends TimetableEvent {
  const TimetableRefreshRequested();

  @override
  List<Object?> get props => [];
}

/// Demande la grille d'emploi du temps d'une classe (conseil pédagogique).
class ClassroomGridRequested extends TimetableEvent {
  final String classroomId;
  final String academicYearId;

  const ClassroomGridRequested({
    required this.classroomId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [classroomId, academicYearId];
}
