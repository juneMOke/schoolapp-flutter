import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_copie_repository.dart';

class GetCopieLogUseCase {
  final EvaluationCopieRepository _repository;

  const GetCopieLogUseCase(this._repository);

  Future<Either<Failure, List<CopieDiffusion>>> call(String evaluationId) =>
      _repository.getCopieLog(evaluationId);
}
