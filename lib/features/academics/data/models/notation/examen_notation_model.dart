import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/examen_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';

part 'examen_notation_model.g.dart';

@JsonSerializable()
class ExamenNotationModel extends Equatable {
  final String evaluationId;
  final String nom;
  final DateTime date;
  final int poids;
  final double maxPoints;
  final double? moyenneGenerale;

  // Enum conservé en String : converti en domaine via `fromApiValue` (repli
  // `unknown` si valeur backend absente ou inconnue).
  final String statutSaisie;
  final double pourcentageSaisie;

  const ExamenNotationModel({
    required this.evaluationId,
    required this.nom,
    required this.date,
    required this.poids,
    required this.maxPoints,
    this.moyenneGenerale,
    required this.statutSaisie,
    required this.pourcentageSaisie,
  });

  factory ExamenNotationModel.fromJson(Map<String, dynamic> json) =>
      _$ExamenNotationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExamenNotationModelToJson(this);

  ExamenNotation toEntity() => ExamenNotation(
    evaluationId: evaluationId,
    nom: nom,
    date: date,
    poids: poids,
    maxPoints: maxPoints,
    moyenneGenerale: moyenneGenerale,
    statutSaisie: StatutSaisieEvaluationX.fromApiValue(statutSaisie),
    pourcentageSaisie: pourcentageSaisie,
  );

  @override
  List<Object?> get props => [
    evaluationId,
    nom,
    date,
    poids,
    maxPoints,
    moyenneGenerale,
    statutSaisie,
    pourcentageSaisie,
  ];
}
