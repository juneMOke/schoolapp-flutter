import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/evaluation_groupe_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/moyenne_eleve_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';

part 'sous_periode_notation_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SousPeriodeNotationModel extends Equatable {
  final String sousPeriodeId;
  final int ordre;

  // Enum conservé en String : converti en domaine via `fromApiValue`.
  final String statut;
  final double? moyenneClasse;
  final int nombreElevesNotes;
  final int nombreEleves50;
  final List<MoyenneEleveModel> moyennesEleves;
  final List<EvaluationGroupeModel> evaluationsParType;

  const SousPeriodeNotationModel({
    required this.sousPeriodeId,
    required this.ordre,
    required this.statut,
    this.moyenneClasse,
    required this.nombreElevesNotes,
    required this.nombreEleves50,
    required this.moyennesEleves,
    required this.evaluationsParType,
  });

  factory SousPeriodeNotationModel.fromJson(Map<String, dynamic> json) =>
      _$SousPeriodeNotationModelFromJson(json);

  Map<String, dynamic> toJson() => _$SousPeriodeNotationModelToJson(this);

  SousPeriodeNotation toEntity() => SousPeriodeNotation(
    sousPeriodeId: sousPeriodeId,
    ordre: ordre,
    statut: StatutPeriodeX.fromApiValue(statut),
    moyenneClasse: moyenneClasse,
    nombreElevesNotes: nombreElevesNotes,
    nombreEleves50: nombreEleves50,
    moyennesEleves: moyennesEleves
        .map((eleve) => eleve.toEntity())
        .toList(growable: false),
    evaluationsParType: evaluationsParType
        .map((groupe) => groupe.toEntity())
        .toList(growable: false),
  );

  @override
  List<Object?> get props => [
    sousPeriodeId,
    ordre,
    statut,
    moyenneClasse,
    nombreElevesNotes,
    nombreEleves50,
    moyennesEleves,
    evaluationsParType,
  ];
}
