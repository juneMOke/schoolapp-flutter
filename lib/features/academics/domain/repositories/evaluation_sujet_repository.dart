import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';

/// Le sujet d'une évaluation : lu en local, écrit en local puis envoyé par
/// l'outbox.
abstract class EvaluationSujetRepository {
  Future<Either<Failure, EvaluationSujet>> getSujet(String evaluationId);
}
