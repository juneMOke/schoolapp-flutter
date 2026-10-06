import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';

sealed class PublicationEvent extends Equatable {
  const PublicationEvent();

  @override
  List<Object?> get props => [];
}

/// Charge l'état des publications et les gardes (écritures en file).
class PublicationContextRequested extends PublicationEvent {
  final String evaluationId;

  const PublicationContextRequested(this.evaluationId);

  @override
  List<Object?> get props => [evaluationId];
}

/// Publie un élément — confirmé par l'utilisateur, envoie un WhatsApp.
class PublicationPublishRequested extends PublicationEvent {
  final String evaluationId;
  final PublicationKind kind;

  const PublicationPublishRequested(this.evaluationId, this.kind);

  @override
  List<Object?> get props => [evaluationId, kind];
}

/// Retire une publication (le WhatsApp parti n'est pas rappelé).
class PublicationWithdrawRequested extends PublicationEvent {
  final String evaluationId;
  final PublicationKind kind;

  const PublicationWithdrawRequested(this.evaluationId, this.kind);

  @override
  List<Object?> get props => [evaluationId, kind];
}
