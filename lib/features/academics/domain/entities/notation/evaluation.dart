import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

/// Évaluation créée sous un cours (réponse `EvaluationDto` du POST de création).
///
/// Le rattachement temporel est exclusif : un EXAMEN porte [periodeScolaireId]
/// (et [sousPeriodeId] nul) ; une INTERRO/DEVOIR porte [sousPeriodeId] (et
/// [periodeScolaireId] nul).
class Evaluation extends Equatable {
  final String id;
  final String coursId;
  final TypeEvaluation type;

  /// Date de l'épreuve (date-only `yyyy-MM-dd`, sans heure).
  final DateTime date;

  /// Barème de l'épreuve, strictement positif.
  final double maxPoints;

  /// Poids de l'épreuve dans la moyenne (défaut backend = 1).
  final int poids;

  /// Renseigné pour INTERRO/DEVOIR, nul pour EXAMEN.
  final String? sousPeriodeId;

  /// Renseigné pour EXAMEN, nul pour INTERRO/DEVOIR.
  final String? periodeScolaireId;

  /// Chapitres couverts par l'évaluation (relation n-n, éventuellement vide).
  final List<String> chapitreIds;

  const Evaluation({
    required this.id,
    required this.coursId,
    required this.type,
    required this.date,
    required this.maxPoints,
    required this.poids,
    this.sousPeriodeId,
    this.periodeScolaireId,
    this.chapitreIds = const [],
  });

  @override
  List<Object?> get props => [
    id,
    coursId,
    type,
    date,
    maxPoints,
    poids,
    sousPeriodeId,
    periodeScolaireId,
    chapitreIds,
  ];
}
