// `dartz` exporte aussi un type `Evaluation` : on le masque au profit de notre
// entité domaine.
import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';

/// Crée une évaluation sous un cours.
///
/// On passe [coursId] directement (path param) et le corps via le modèle de
/// requête [CreateEvaluationRequest] (vrai modèle du domaine, porteur de ses
/// invariants), sans wrapper de params dédié.
class CreateEvaluationUseCase {
  final CourseRepository _repository;

  const CreateEvaluationUseCase(this._repository);

  Future<Either<Failure, Evaluation>> call(
    String coursId,
    CreateEvaluationRequest request,
  ) => _repository.createEvaluation(coursId, request);
}
