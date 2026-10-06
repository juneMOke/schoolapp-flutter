import 'package:equatable/equatable.dart';

sealed class CoursNotationEvent extends Equatable {
  const CoursNotationEvent();
}

/// Demande le chargement du détail de notation d'un cours.
///
/// Émis au montage de la feature (état initial -> chargement). [silent] :
/// relecture sur place (retour d'une évaluation) — le détail déjà affiché
/// reste à l'écran, sans repasser par le squelette.
class CoursNotationRequested extends CoursNotationEvent {
  final String coursId;
  final bool silent;

  const CoursNotationRequested({required this.coursId, this.silent = false});

  @override
  List<Object?> get props => [coursId, silent];
}
