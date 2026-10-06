import 'package:equatable/equatable.dart';

/// Une question du sujet d'une évaluation.
///
/// Son numéro (« Q2 ») n'est pas stocké : c'est sa place dans la liste. Les
/// [points] restent nuls tant que le professeur ne les a pas saisis — une
/// question « à compléter » s'enregistre, le barème n'est jamais bloquant.
///
/// [reponseAttendue] n'est visible que du professeur : elle n'apparaît sur une
/// copie que si l'option « Réponses » est cochée (corrigé).
class SujetQuestion extends Equatable {
  final String id;
  final String enonce;
  final double? points;
  final String? reponseAttendue;

  const SujetQuestion({
    required this.id,
    this.enonce = '',
    this.points,
    this.reponseAttendue,
  });

  /// Énoncé vide ou points non strictement positifs : badge « À compléter ».
  bool get isIncomplete =>
      enonce.trim().isEmpty || points == null || points! <= 0;

  SujetQuestion copyWith({
    String? id,
    String? enonce,
    double? Function()? points,
    String? Function()? reponseAttendue,
  }) => SujetQuestion(
    id: id ?? this.id,
    enonce: enonce ?? this.enonce,
    points: points != null ? points() : this.points,
    reponseAttendue: reponseAttendue != null
        ? reponseAttendue()
        : this.reponseAttendue,
  );

  @override
  List<Object?> get props => [id, enonce, points, reponseAttendue];
}
