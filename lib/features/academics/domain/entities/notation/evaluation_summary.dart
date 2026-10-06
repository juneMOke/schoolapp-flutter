import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

/// Résumé d'une évaluation. [statutSaisie] est dérivé (non persisté) ; [nom]
/// est le titre stocké, ou le nom que le serveur renvoie.
class EvaluationSummary extends Equatable {
  final String id;
  final TypeEvaluation type;

  /// Titre stocké (calculé à la création, ou nom renvoyé par le serveur) ;
  /// `null` = aucun titre : l'écran dérive « Interrogation du 12 juin 2026 ».
  final String? nom;

  /// Titres des chapitres couverts par l'évaluation.
  final List<String> chapitres;
  final DateTime date;
  final double maxPoints;
  final int poids;
  final StatutSaisieEvaluation statutSaisie;

  /// Pourcentage d'élèves de la classe dont la note est saisie (décidée).
  final double pourcentageSaisie;

  /// Code du backstop `422` terminal ayant rejeté la création offline
  /// (`PERIOD_CLOSED`/`EXAM_NOT_ALLOWED`/`MAX_REACHED`/`REJECTED`) — `null`
  /// hors rejet (chemin online, ou évaluation acceptée).
  final String? rejectionCode;

  const EvaluationSummary({
    required this.id,
    required this.type,
    this.nom,
    required this.chapitres,
    required this.date,
    required this.maxPoints,
    required this.poids,
    required this.statutSaisie,
    required this.pourcentageSaisie,
    this.rejectionCode,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    nom,
    chapitres,
    date,
    maxPoints,
    poids,
    statutSaisie,
    pourcentageSaisie,
    rejectionCode,
  ];
}
