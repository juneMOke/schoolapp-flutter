import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_sujet_repository.dart';

class GetEvaluationSujetUseCase {
  final EvaluationSujetRepository _repository;

  const GetEvaluationSujetUseCase(this._repository);

  Future<Either<Failure, EvaluationSujet>> call(String evaluationId) =>
      _repository.getSujet(evaluationId);
}
