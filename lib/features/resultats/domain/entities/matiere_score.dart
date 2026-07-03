import 'package:equatable/equatable.dart';

/// Score d'une matière (branche) : sert aux top3 / bottom3 de la vue focus.
///
/// [pourcentage] `null` = « non noté » (rendu « — »).
class MatiereScore extends Equatable {
  final String brancheId;
  final String brancheNom;
  final double? pourcentage;

  const MatiereScore({
    required this.brancheId,
    required this.brancheNom,
    this.pourcentage,
  });

  @override
  List<Object?> get props => [brancheId, brancheNom, pourcentage];
}
