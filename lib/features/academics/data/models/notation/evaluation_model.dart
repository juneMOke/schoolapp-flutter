import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

part 'evaluation_model.g.dart';

/// Modèle de la réponse `EvaluationDto` (POST création d'évaluation).
@JsonSerializable()
class EvaluationModel extends Equatable {
  final String id;
  final String coursId;

  // Enum conservé en String : converti en domaine via `fromApiValue`.
  final String type;

  @JsonKey(
    fromJson: DateOnlyJsonHelper.fromJson,
    toJson: DateOnlyJsonHelper.toJson,
  )
  final DateTime date;

  final double maxPoints;
  final int poids;
  final String? sousPeriodeId;
  final String? periodeScolaireId;

  @JsonKey(defaultValue: <String>[])
  final List<String> chapitreIds;

  const EvaluationModel({
    required this.id,
    required this.coursId,
    required this.type,
    required this.date,
    required this.maxPoints,
    required this.poids,
    this.sousPeriodeId,
    this.periodeScolaireId,
    this.chapitreIds = const [],
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluationModelToJson(this);

  Evaluation toEntity() => Evaluation(
    id: id,
    coursId: coursId,
    type: TypeEvaluationX.fromApiValue(type),
    date: date,
    maxPoints: maxPoints,
    poids: poids,
    sousPeriodeId: sousPeriodeId,
    periodeScolaireId: periodeScolaireId,
    chapitreIds: chapitreIds,
  );

  @override
  List<Object?> get props => [
    id,
    coursId,
    type,
    date,
    maxPoints,
    poids,
    sousPeriodeId,
    periodeScolaireId,
    chapitreIds,
  ];
}
