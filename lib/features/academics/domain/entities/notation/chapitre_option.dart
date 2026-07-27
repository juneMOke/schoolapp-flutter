import 'package:equatable/equatable.dart';

/// Chapitre cochable à la création d'une évaluation (bundle
/// `grades-referential`, lecture seule ; `contenu` volontairement omis).
class ChapitreOption extends Equatable {
  final String id;
  final String titre;
  final int ordre;

  const ChapitreOption({
    required this.id,
    required this.titre,
    required this.ordre,
  });

  @override
  List<Object?> get props => [id, titre, ordre];
}
