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
