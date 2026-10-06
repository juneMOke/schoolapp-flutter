import 'package:equatable/equatable.dart';

/// Ce qu'une évaluation peut publier aux parents. Chaque publication a son
/// état propre et se retire indépendamment.
enum PublicationKind {
  /// Sujet du devoir (DEVOIR seulement) : énoncés, points, cadre — jamais les
  /// réponses.
  sujet('sujet'),

  /// Corrigé : questions et réponses attendues, une fois tout corrigé.
  corrige('corrige'),

  /// Notes : chaque parent ne reçoit que celle de son enfant.
  notes('notes');

  const PublicationKind(this.pathSegment);

  /// Segment de route (`…/publications/{segment}`) et clé du delta.
  final String pathSegment;
}

/// Une publication en cours : quand, mise à jour quand, et sa révision.
class PublicationEtat extends Equatable {
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final int revision;

  const PublicationEtat({
    required this.publishedAt,
    this.updatedAt,
    this.revision = 1,
  });

  @override
  List<Object?> get props => [publishedAt, updatedAt, revision];
}

/// Les trois publications d'une évaluation ; `null` = non publié (jamais, ou
/// retiré).
class EvaluationPublications extends Equatable {
  final PublicationEtat? sujet;
  final PublicationEtat? corrige;
  final PublicationEtat? notes;

  const EvaluationPublications({this.sujet, this.corrige, this.notes});

  static const EvaluationPublications none = EvaluationPublications();

  PublicationEtat? of(PublicationKind kind) => switch (kind) {
    PublicationKind.sujet => sujet,
    PublicationKind.corrige => corrige,
    PublicationKind.notes => notes,
  };

  EvaluationPublications withKind(
    PublicationKind kind,
    PublicationEtat? etat,
  ) => EvaluationPublications(
    sujet: kind == PublicationKind.sujet ? etat : sujet,
    corrige: kind == PublicationKind.corrige ? etat : corrige,
    notes: kind == PublicationKind.notes ? etat : notes,
  );

  @override
  List<Object?> get props => [sujet, corrige, notes];
}
