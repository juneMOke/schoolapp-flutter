import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';

/// Examen d'une période scolaire avec sa moyenne générale de classe (sur les
/// élèves notés). [moyenneGenerale] est `null` tant qu'aucune note n'est comptée.
class ExamenNotation extends Equatable {
  final String evaluationId;
  final String nom;
  final DateTime date;
  final int poids;
  final double maxPoints;
  final double? moyenneGenerale;
  final StatutSaisieEvaluation statutSaisie;
  final double pourcentageSaisie;

  const ExamenNotation({
    required this.evaluationId,
    required this.nom,
    required this.date,
    required this.poids,
    required this.maxPoints,
    this.moyenneGenerale,
    required this.statutSaisie,
    required this.pourcentageSaisie,
  });

  @override
  List<Object?> get props => [
    evaluationId,
    nom,
    date,
    poids,
    maxPoints,
    moyenneGenerale,
    statutSaisie,
    pourcentageSaisie,
  ];
}
