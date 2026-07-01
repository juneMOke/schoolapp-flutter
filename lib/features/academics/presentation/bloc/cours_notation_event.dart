import 'package:equatable/equatable.dart';

sealed class CoursNotationEvent extends Equatable {
  const CoursNotationEvent();
}

/// Demande le chargement du détail de notation d'un cours.
///
/// Émis au montage de la feature (état initial -> chargement).
class CoursNotationRequested extends CoursNotationEvent {
  final String coursId;

  const CoursNotationRequested({required this.coursId});

  @override
  List<Object?> get props => [coursId];
}
