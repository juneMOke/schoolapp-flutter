import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/extreme_eleve.dart';

/// Synthèse de classe pour une grande période : effectif, seuil de réussite
/// appliqué, moyenne de classe et répartition réussites / échecs / non classés.
///
/// [moyenneClasse] est `null` si aucun élève n'est classé ; [best] / [worst]
/// sont `null` dans le même cas (aucun extrême à afficher).
class ResultatsClasseStats extends Equatable {
  final int effectif;

  /// Seuil de réussite (%) réellement appliqué par le backend (défaut 50).
  final double seuil;

  /// Moyenne générale de la classe (%) ; `null` si aucun élève classé.
  final double? moyenneClasse;
  final int reussites;
  final int echecs;
  final int nonClasses;
  final ExtremeEleve? best;
  final ExtremeEleve? worst;

  const ResultatsClasseStats({
    required this.effectif,
    required this.seuil,
    this.moyenneClasse,
    required this.reussites,
    required this.echecs,
    required this.nonClasses,
    this.best,
    this.worst,
  });

  @override
  List<Object?> get props => [
    effectif,
    seuil,
    moyenneClasse,
    reussites,
    echecs,
    nonClasses,
    best,
    worst,
  ];
}
