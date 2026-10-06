import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

sealed class EvalDetailEvent extends Equatable {
  const EvalDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Charge (ou recharge) le sujet et l'avancement des notes d'une évaluation.
/// Un rechargement garde l'écran affiché : il ne repasse pas par le squelette.
class EvalDetailRequested extends EvalDetailEvent {
  final String evaluationId;

  const EvalDetailRequested(this.evaluationId);

  @override
  List<Object?> get props => [evaluationId];
}

/// Enregistre le sujet d'un bloc (spec S4). [maxPoints] aligne le maximum de
/// l'évaluation sur la somme des points, quand aucune note n'est posée.
class EvalDetailSujetSaveRequested extends EvalDetailEvent {
  final String evaluationId;
  final EvaluationCadre cadre;
  final List<SujetQuestion> questions;
  final double? maxPoints;

  const EvalDetailSujetSaveRequested({
    required this.evaluationId,
    required this.cadre,
    required this.questions,
    this.maxPoints,
  });

  @override
  List<Object?> get props => [evaluationId, cadre, questions, maxPoints];
}
