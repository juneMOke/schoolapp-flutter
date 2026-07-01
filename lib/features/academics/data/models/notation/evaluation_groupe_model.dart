import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/evaluation_summary_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_groupe.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

part 'evaluation_groupe_model.g.dart';

@JsonSerializable(explicitToJson: true)
class EvaluationGroupeModel extends Equatable {
  // Enum conservé en String : converti en domaine via `fromApiValue`.
  final String type;
  final List<EvaluationSummaryModel> evaluations;

  const EvaluationGroupeModel({required this.type, required this.evaluations});

  factory EvaluationGroupeModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationGroupeModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluationGroupeModelToJson(this);

  EvaluationGroupe toEntity() => EvaluationGroupe(
    type: TypeEvaluationX.fromApiValue(type),
    evaluations: evaluations
        .map((evaluation) => evaluation.toEntity())
        .toList(growable: false),
  );

  @override
  List<Object?> get props => [type, evaluations];
}
