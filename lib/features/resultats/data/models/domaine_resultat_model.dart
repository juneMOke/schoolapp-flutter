import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/data/models/branche_resultat_model.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/domaine_resultat.dart';

part 'domaine_resultat_model.g.dart';

/// Nœud **récursif** de l'arbre par domaine.
///
/// `@JsonSerializable` gère l'auto-référence : le `.g.dart` généré rappelle
/// `DomaineResultatModel.fromJson` pour [sousRubriques]. Les défauts `const []`
/// (honorés par le générateur pour une clé absente ou `null`) rendent le parsing
/// défensif. Un nœud porte **soit** [sousRubriques] **soit** [branches].
@JsonSerializable(explicitToJson: true)
class DomaineResultatModel extends Equatable {
  final String rubriqueId;
  final String? label;
  final bool produitSousTotal;
  final double obtenu;
  final double max;
  final double? pourcentage;
  final List<DomaineResultatModel> sousRubriques;
  final List<BrancheResultatModel> branches;

  const DomaineResultatModel({
    required this.rubriqueId,
    this.label,
    required this.produitSousTotal,
    required this.obtenu,
    required this.max,
    this.pourcentage,
    this.sousRubriques = const [],
    this.branches = const [],
  });

  factory DomaineResultatModel.fromJson(Map<String, dynamic> json) =>
      _$DomaineResultatModelFromJson(json);

  Map<String, dynamic> toJson() => _$DomaineResultatModelToJson(this);

  DomaineResultat toEntity() => DomaineResultat(
    rubriqueId: rubriqueId,
    label: label,
    produitSousTotal: produitSousTotal,
    obtenu: obtenu,
    max: max,
    pourcentage: pourcentage,
    sousRubriques: sousRubriques
        .map((noeud) => noeud.toEntity())
        .toList(growable: false),
    branches: branches
        .map((branche) => branche.toEntity())
        .toList(growable: false),
  );

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
