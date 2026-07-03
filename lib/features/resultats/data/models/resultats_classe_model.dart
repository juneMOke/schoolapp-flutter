import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultat_eleve_ligne_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultats_classe_stats_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/sous_periode_colonne_model.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe.dart';

part 'resultats_classe_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ResultatsClasseModel extends Equatable {
  final String classroomId;
  final String periodeScolaireId;
  final int periodeOrdre;
  final List<SousPeriodeColonneModel> sousPeriodes;
  final ResultatsClasseStatsModel stats;
  final List<ResultatEleveLigneModel> lignes;

  const ResultatsClasseModel({
    required this.classroomId,
    required this.periodeScolaireId,
    required this.periodeOrdre,
    required this.sousPeriodes,
    required this.stats,
    required this.lignes,
  });

  factory ResultatsClasseModel.fromJson(Map<String, dynamic> json) =>
      _$ResultatsClasseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResultatsClasseModelToJson(this);

  ResultatsClasse toEntity() => ResultatsClasse(
    classroomId: classroomId,
    periodeScolaireId: periodeScolaireId,
    periodeOrdre: periodeOrdre,
    sousPeriodes: sousPeriodes
        .map((colonne) => colonne.toEntity())
        .toList(growable: false),
    stats: stats.toEntity(),
    lignes: lignes.map((ligne) => ligne.toEntity()).toList(growable: false),
  );

  @override
  List<Object?> get props => [
    classroomId,
    periodeScolaireId,
    periodeOrdre,
    sousPeriodes,
    stats,
    lignes,
  ];
}
