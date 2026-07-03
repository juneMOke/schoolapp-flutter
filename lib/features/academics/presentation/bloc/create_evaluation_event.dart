import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';

sealed class CreateEvaluationEvent extends Equatable {
  const CreateEvaluationEvent();
}

/// Soumission utilisateur de la création d'une évaluation sous [coursId].
///
/// Déclenché par une action explicite (pas au montage). Le BLoC ignore tout
/// nouveau [CreateEvaluationSubmitted] tant qu'une création est en cours
/// (garde anti-double-envoi).
class CreateEvaluationSubmitted extends CreateEvaluationEvent {
  final String coursId;
  final CreateEvaluationRequest request;

  const CreateEvaluationSubmitted({
    required this.coursId,
    required this.request,
  });

  @override
  List<Object?> get props => [coursId, request];
}

/// Réinitialise l'état de création (après succès/échec, ex. fermeture du
/// formulaire) pour repartir sur [CreateEvaluationStatus.initial].
class CreateEvaluationReset extends CreateEvaluationEvent {
  const CreateEvaluationReset();

  @override
  List<Object?> get props => [];
}
