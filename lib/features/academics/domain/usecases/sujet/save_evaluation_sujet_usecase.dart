import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_sujet_repository.dart';

class SaveEvaluationSujetUseCase {
  final EvaluationSujetRepository _repository;

  const SaveEvaluationSujetUseCase(this._repository);

  Future<Either<Failure, EvaluationSujet>> call(
    String evaluationId, {
    required EvaluationCadre cadre,
    required List<SujetQuestion> questions,
    double? maxPoints,
  }) => _repository.saveSujet(
    evaluationId,
    cadre: cadre.normalized(),
    questions: questions,
    maxPoints: maxPoints,
  );
}
