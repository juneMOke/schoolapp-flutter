import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

/// Résumé d'une évaluation. [nom] et [statutSaisie] sont dérivés côté backend
/// (non persistés) : [nom] est un libellé « type + date », ex.
/// « Interrogation du 2025-11-10 ».
class EvaluationSummary extends Equatable {
  final String id;
  final TypeEvaluation type;
  final String nom;

  /// Titres des chapitres couverts par l'évaluation.
  final List<String> chapitres;
  final DateTime date;
  final double maxPoints;
  final int poids;
  final StatutSaisieEvaluation statutSaisie;

  /// Pourcentage d'élèves de la classe dont la note est saisie (décidée).
  final double pourcentageSaisie;

  const EvaluationSummary({
    required this.id,
    required this.type,
    required this.nom,
    required this.chapitres,
    required this.date,
    required this.maxPoints,
    required this.poids,
    required this.statutSaisie,
    required this.pourcentageSaisie,
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
  ];
}
