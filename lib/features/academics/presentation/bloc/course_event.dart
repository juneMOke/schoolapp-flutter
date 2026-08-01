import 'package:equatable/equatable.dart';

sealed class CourseEvent extends Equatable {
  const CourseEvent();
}

/// Demande le chargement des cours de l'enseignant connecté.
///
/// Émis automatiquement au montage de la feature (état initial -> chargement).
class MyCoursesRequested extends CourseEvent {
  const MyCoursesRequested();

  @override
  List<Object?> get props => [];
}

/// Relit **silencieusement** la liste des cours, sans état de chargement.
///
/// Émis quand un pull vient de rafraîchir le cache local ([PullCompletionBus]) :
/// l'écran a lu le local avant que le réseau réponde. Pendant de
/// [TimetableRefreshRequested] côté emploi du temps.
class MyCoursesRefreshRequested extends CourseEvent {
  const MyCoursesRefreshRequested();

  @override
  List<Object?> get props => [];
}
