import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/publication_context.dart';

/// Les publications d'une évaluation aux parents. **En ligne** : publier
/// envoie un WhatsApp, rien ne passe par l'outbox ni ne se rejoue seul.
abstract class EvaluationPublicationRepository {
  /// État local et gardes (écritures encore en file).
  Future<Either<Failure, PublicationContext>> getContext(String evaluationId);

  Future<Either<Failure, PublicationEtat>> publish(
    String evaluationId,
    PublicationKind kind,
  );

  Future<Either<Failure, Unit>> withdraw(
    String evaluationId,
    PublicationKind kind,
  );
}
