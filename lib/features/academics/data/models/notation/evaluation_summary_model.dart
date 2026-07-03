import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

part 'evaluation_summary_model.g.dart';

@JsonSerializable()
class EvaluationSummaryModel extends Equatable {
  final String id;

  // Enums conservés en String : convertis en domaine via `fromApiValue`.
  final String type;
  final String nom;
  final List<String> chapitres;
  final DateTime date;
  final double maxPoints;
  final int poids;
  final String statutSaisie;
  final double pourcentageSaisie;

  const EvaluationSummaryModel({
    required this.id,
    required this.type,
    required this.nom,
    required this.chapitres,
    required this.date,
    required this.maxPoints,
    required this.poids,
    required this.statutSaisie,
    required this.pourcentageSaisie,
  });

  factory EvaluationSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluationSummaryModelToJson(this);

  EvaluationSummary toEntity() => EvaluationSummary(
    id: id,
    type: TypeEvaluationX.fromApiValue(type),
    nom: nom,
    chapitres: chapitres,
    date: date,
    maxPoints: maxPoints,
    poids: poids,
    statutSaisie: StatutSaisieEvaluationX.fromApiValue(statutSaisie),
    pourcentageSaisie: pourcentageSaisie,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    nom,
    chapitres,
    date,
    maxPoints,
    poids,
    statutSaisie,
    pourcentageSaisie,
  ];
}
