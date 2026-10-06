import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/publication_context.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_publication_repository.dart';

class GetPublicationContextUseCase {
  final EvaluationPublicationRepository _repository;

  const GetPublicationContextUseCase(this._repository);

  Future<Either<Failure, PublicationContext>> call(String evaluationId) =>
      _repository.getContext(evaluationId);
}

class PublishEvaluationUseCase {
  final EvaluationPublicationRepository _repository;

  const PublishEvaluationUseCase(this._repository);

  Future<Either<Failure, PublicationEtat>> call(
    String evaluationId,
    PublicationKind kind,
  ) => _repository.publish(evaluationId, kind);
}

class WithdrawPublicationUseCase {
  final EvaluationPublicationRepository _repository;

  const WithdrawPublicationUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    String evaluationId,
    PublicationKind kind,
  ) => _repository.withdraw(evaluationId, kind);
}
