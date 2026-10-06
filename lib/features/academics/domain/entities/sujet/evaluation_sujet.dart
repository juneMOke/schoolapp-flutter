import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

/// Où en est l'envoi du sujet au serveur.
enum SujetEnvoi {
  /// Jamais modifié depuis la création : le cadre est parti avec l'évaluation.
  initial,

  /// Modifié sur la tablette, pas encore accusé par le serveur.
  enAttente,

  /// Accusé par le serveur.
  envoye,

  /// Refusé par le serveur (voir [EvaluationSujet.rejectionCode]).
  refuse,
}

/// Le sujet d'une évaluation : son cadre et ses questions. Il se remplace d'un
/// bloc — jamais une question seule.
class EvaluationSujet extends Equatable {
  final EvaluationCadre cadre;
  final List<SujetQuestion> questions;
  final SujetEnvoi envoi;
  final String? rejectionCode;

  const EvaluationSujet({
    this.cadre = EvaluationCadre.empty,
    this.questions = const [],
    this.envoi = SujetEnvoi.initial,
    this.rejectionCode,
  });

  /// Somme des points des questions (une question sans points compte 0).
  double get totalPoints =>
      questions.fold(0, (sum, q) => sum + (q.points ?? 0));

  int get incompleteCount => questions.where((q) => q.isIncomplete).length;

  bool get isEmpty => questions.isEmpty;

  @override
  List<Object?> get props => [cadre, questions, envoi, rejectionCode];
}
