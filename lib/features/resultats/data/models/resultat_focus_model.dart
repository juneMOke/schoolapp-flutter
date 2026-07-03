import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/data/models/bulletin_domaine_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/focus_entete_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/matiere_score_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/progression_point_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/synthese_model.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_focus.dart';

part 'resultat_focus_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ResultatFocusModel extends Equatable {
  final String classroomId;
  final String periodeScolaireId;
  final int periodeOrdre;
  final FocusEnteteModel entete;
  final List<ProgressionPointModel> progression;
  final double? deltaPts;
  final List<MatiereScoreModel> topMatieres;
  final List<MatiereScoreModel> bottomMatieres;

  /// `null` (élève non classé sur le groupe) est un cas valide, pas une erreur.
  final BulletinDomaineModel? bulletinParDomaine;
  final SyntheseModel synthese;

  const ResultatFocusModel({
    required this.classroomId,
    required this.periodeScolaireId,
    required this.periodeOrdre,
    required this.entete,
    required this.progression,
    this.deltaPts,
    required this.topMatieres,
    required this.bottomMatieres,
    this.bulletinParDomaine,
    required this.synthese,
  });

  factory ResultatFocusModel.fromJson(Map<String, dynamic> json) =>
      _$ResultatFocusModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResultatFocusModelToJson(this);

  ResultatFocus toEntity() => ResultatFocus(
    classroomId: classroomId,
    periodeScolaireId: periodeScolaireId,
    periodeOrdre: periodeOrdre,
    entete: entete.toEntity(),
    progression: progression
        .map((point) => point.toEntity())
        .toList(growable: false),
    deltaPts: deltaPts,
    topMatieres: topMatieres
        .map((matiere) => matiere.toEntity())
        .toList(growable: false),
    bottomMatieres: bottomMatieres
        .map((matiere) => matiere.toEntity())
        .toList(growable: false),
    bulletinParDomaine: bulletinParDomaine?.toEntity(),
    synthese: synthese.toEntity(),
  );

  @override
  List<Object?> get props => [
    classroomId,
    periodeScolaireId,
    periodeOrdre,
    entete,
    progression,
    deltaPts,
    topMatieres,
    bottomMatieres,
    bulletinParDomaine,
    synthese,
  ];
}
