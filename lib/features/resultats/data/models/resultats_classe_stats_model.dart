import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/data/models/extreme_eleve_model.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe_stats.dart';

part 'resultats_classe_stats_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ResultatsClasseStatsModel extends Equatable {
  final int effectif;
  final double seuil;

  /// `null` si aucun élève classé : conservé tel quel.
  final double? moyenneClasse;
  final int reussites;
  final int echecs;
  final int nonClasses;
  final ExtremeEleveModel? best;
  final ExtremeEleveModel? worst;

  const ResultatsClasseStatsModel({
    required this.effectif,
    required this.seuil,
    this.moyenneClasse,
    required this.reussites,
    required this.echecs,
    required this.nonClasses,
    this.best,
    this.worst,
  });

  factory ResultatsClasseStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ResultatsClasseStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResultatsClasseStatsModelToJson(this);

  ResultatsClasseStats toEntity() => ResultatsClasseStats(
    effectif: effectif,
    seuil: seuil,
    moyenneClasse: moyenneClasse,
    reussites: reussites,
    echecs: echecs,
    nonClasses: nonClasses,
    best: best?.toEntity(),
    worst: worst?.toEntity(),
  );

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
