import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_copie_repository.dart';

class LogCopieDiffusionUseCase {
  final EvaluationCopieRepository _repository;

  const LogCopieDiffusionUseCase(this._repository);

  Future<Either<Failure, CopieDiffusion>> call(
    String evaluationId, {
    required CopieKind kind,
    CopieCanal? canal,
    required bool corrige,
  }) => _repository.logDiffusion(
    evaluationId,
    kind: kind,
    canal: canal,
    corrige: corrige,
  );
}
