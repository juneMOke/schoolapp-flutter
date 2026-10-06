import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

/// Le sujet d'une évaluation : lu en local, écrit en local puis envoyé par
/// l'outbox.
abstract class EvaluationSujetRepository {
  Future<Either<Failure, EvaluationSujet>> getSujet(String evaluationId);

  /// Remplace le sujet d'un bloc. [maxPoints], s'il est fourni, aligne le
  /// maximum de l'évaluation (« Ajuster le maximum »). Renvoie le sujet relu.
  Future<Either<Failure, EvaluationSujet>> saveSujet(
    String evaluationId, {
    required EvaluationCadre cadre,
    required List<SujetQuestion> questions,
    double? maxPoints,
  });

  /// Renvoie le sujet refusé en `MAX_LOCKED` sans toucher au maximum : des
  /// notes sont posées, il ne change plus.
  Future<Either<Failure, EvaluationSujet>> resendSujetWithoutMax(
    String evaluationId,
  );
}
