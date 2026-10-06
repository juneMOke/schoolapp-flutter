import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';

/// L'état des publications d'une évaluation et ce qui retient une
/// publication sur la tablette.
///
/// Le serveur juge sur SES données : une évaluation, un sujet ou des notes
/// encore en file feraient publier autre chose que ce que l'écran montre —
/// ou refuser en `EVALUATION_INCOMPLETE` alors que la tablette affiche tout.
class PublicationContext extends Equatable {
  final EvaluationPublications publications;

  /// L'évaluation n'est pas encore connue du serveur.
  final bool evaluationPending;

  /// Le serveur n'a pas la version affichée du sujet (en file ou refusée).
  final bool sujetPending;

  /// Des notes de l'évaluation attendent leur envoi.
  final bool notesPending;

  const PublicationContext({
    this.publications = EvaluationPublications.none,
    this.evaluationPending = false,
    this.sujetPending = false,
    this.notesPending = false,
  });

  /// Une écriture de l'évaluation est encore en file.
  bool get anythingPending => evaluationPending || sujetPending || notesPending;

  PublicationContext withPublications(EvaluationPublications p) =>
      PublicationContext(
        publications: p,
        evaluationPending: evaluationPending,
        sujetPending: sujetPending,
        notesPending: notesPending,
      );

  @override
  List<Object?> get props => [
    publications,
    evaluationPending,
    sujetPending,
    notesPending,
  ];
}

/// Le serveur a refusé une publication ([code] lu dans `detailCode`) ;
/// [saisies] et [effectif] accompagnent `EVALUATION_INCOMPLETE`.
class PublicationRefusedFailure extends Failure {
  final String code;
  final int? saisies;
  final int? effectif;

  const PublicationRefusedFailure(this.code, {this.saisies, this.effectif})
    : super(code);

  @override
  List<Object?> get props => [code, saisies, effectif];
}
