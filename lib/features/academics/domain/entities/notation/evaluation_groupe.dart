import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

/// Évaluations d'une sous-période regroupées par type.
class EvaluationGroupe extends Equatable {
  final TypeEvaluation type;
  final List<EvaluationSummary> evaluations;

  const EvaluationGroupe({required this.type, required this.evaluations});

  @override
  List<Object?> get props => [type, evaluations];
}
