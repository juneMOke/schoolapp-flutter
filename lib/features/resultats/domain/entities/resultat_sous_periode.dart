import 'package:equatable/equatable.dart';

/// Cellule `%` d'un élève pour une sous-période donnée (vue classe).
///
/// [pourcentage] `null` = « non noté » (rendu « — ») : à **distinguer de `0`**.
/// Aligné index par index sur les colonnes `sousPeriodes` (même [sousPeriodeId]).
class ResultatSousPeriode extends Equatable {
  final String sousPeriodeId;
  final double? pourcentage;

  const ResultatSousPeriode({required this.sousPeriodeId, this.pourcentage});

  @override
  List<Object?> get props => [sousPeriodeId, pourcentage];
}
