import 'package:equatable/equatable.dart';

/// Feuille de l'arbre par domaine : une matière (branche) du bulletin.
///
/// [pourcentage] `null` = « non noté » (rendu « — »).
class BrancheResultat extends Equatable {
  final String ligneBaremeId;
  final String brancheId;
  final String brancheNom;
  final double obtenu;
  final double max;
  final double? pourcentage;

  const BrancheResultat({
    required this.ligneBaremeId,
    required this.brancheId,
    required this.brancheNom,
    required this.obtenu,
    required this.max,
    this.pourcentage,
  });

  @override
  List<Object?> get props => [
    ligneBaremeId,
    brancheId,
    brancheNom,
    obtenu,
    max,
    pourcentage,
  ];
}
