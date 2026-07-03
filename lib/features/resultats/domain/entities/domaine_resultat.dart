import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/branche_resultat.dart';

/// Nœud **récursif** de l'arbre par domaine (mêmes chiffres que le bulletin
/// officiel).
///
/// Un nœud porte **soit** des [sousRubriques] (auto-référence : sous-domaines)
/// **soit** des [branches] (feuilles = matières) ; l'autre liste est vide. On se
/// distingue « domaine » vs « feuille de branches » par la liste non vide.
/// [produitSousTotal] met en avant un sous-total. [pourcentage] `null` = « — ».
class DomaineResultat extends Equatable {
  final String rubriqueId;
  final String? label;
  final bool produitSousTotal;
  final double obtenu;
  final double max;
  final double? pourcentage;
  final List<DomaineResultat> sousRubriques;
  final List<BrancheResultat> branches;

  const DomaineResultat({
    required this.rubriqueId,
    this.label,
    required this.produitSousTotal,
    required this.obtenu,
    required this.max,
    this.pourcentage,
    this.sousRubriques = const [],
    this.branches = const [],
  });

  @override
  List<Object?> get props => [
    rubriqueId,
    label,
    produitSousTotal,
    obtenu,
    max,
    pourcentage,
    sousRubriques,
    branches,
  ];
}
