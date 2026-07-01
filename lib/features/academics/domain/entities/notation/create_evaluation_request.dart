import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

/// Corps de la requête de création d'une évaluation, **garantissant
/// l'exclusivité du rattachement temporel par construction** via ses deux
/// factories :
///
/// - [CreateEvaluationRequest.examen] → type EXAMEN + [periodeScolaireId]
///   (jamais [sousPeriodeId]) ;
/// - [CreateEvaluationRequest.journaliere] → type INTERRO/DEVOIR +
///   [sousPeriodeId] (jamais [periodeScolaireId]).
///
/// Invariants reflétés côté client (verrouillés backend, sinon 400) — garantis
/// par construction ET validés à l'exécution (les factories lèvent une
/// [ArgumentError], y compris en build release, là où un `assert` serait
/// supprimé) :
/// 1. rattachement temporel exclusif (un seul des deux ids selon le type) ;
/// 2. [maxPoints] strictement positif ;
/// 3. [poids] absent (`null` ⟹ défaut backend = 1) ou strictement positif ;
/// 4. id temporel pertinent non vide.
class CreateEvaluationRequest extends Equatable {
  final TypeEvaluation type;
  final DateTime date;
  final double maxPoints;

  /// Poids de l'épreuve. `null` ⟹ non envoyé (le backend applique 1).
  final int? poids;

  /// Renseigné pour INTERRO/DEVOIR, nul pour EXAMEN.
  final String? sousPeriodeId;

  /// Renseigné pour EXAMEN, nul pour INTERRO/DEVOIR.
  final String? periodeScolaireId;

  /// Chapitres couverts (relation n-n, éventuellement vide).
  final List<String> chapitreIds;

  const CreateEvaluationRequest._({
    required this.type,
    required this.date,
    required this.maxPoints,
    this.poids,
    this.sousPeriodeId,
    this.periodeScolaireId,
    this.chapitreIds = const [],
  });

  /// Évaluation de type EXAMEN, rattachée à une **période scolaire**.
  ///
  /// [sousPeriodeId] est volontairement absent : l'exclusivité temporelle est
  /// garantie par construction.
  factory CreateEvaluationRequest.examen({
    required DateTime date,
    required double maxPoints,
    required String periodeScolaireId,
    int? poids,
    List<String> chapitreIds = const [],
  }) {
    _validateMaxPoints(maxPoints);
    _validatePoids(poids);
    _validateId(periodeScolaireId, 'periodeScolaireId');
    return CreateEvaluationRequest._(
      type: TypeEvaluation.examen,
      date: date,
      maxPoints: maxPoints,
      poids: poids,
      periodeScolaireId: periodeScolaireId,
      chapitreIds: chapitreIds,
    );
  }

  /// Évaluation journalière (INTERRO ou DEVOIR), rattachée à une
  /// **sous-période**.
  ///
  /// [periodeScolaireId] est volontairement absent : l'exclusivité temporelle
  /// est garantie par construction. [type] est restreint à interro/devoir.
  factory CreateEvaluationRequest.journaliere({
    required TypeEvaluation type,
    required DateTime date,
    required double maxPoints,
    required String sousPeriodeId,
    int? poids,
    List<String> chapitreIds = const [],
  }) {
    if (type != TypeEvaluation.interro && type != TypeEvaluation.devoir) {
      throw ArgumentError.value(
        type,
        'type',
        'journaliere n\'accepte que INTERRO ou DEVOIR',
      );
    }
    _validateMaxPoints(maxPoints);
    _validatePoids(poids);
    _validateId(sousPeriodeId, 'sousPeriodeId');
    return CreateEvaluationRequest._(
      type: type,
      date: date,
      maxPoints: maxPoints,
      poids: poids,
      sousPeriodeId: sousPeriodeId,
      chapitreIds: chapitreIds,
    );
  }

  static void _validateMaxPoints(double maxPoints) {
    if (maxPoints <= 0) {
      throw ArgumentError.value(
        maxPoints,
        'maxPoints',
        'doit être strictement positif',
      );
    }
  }

  static void _validatePoids(int? poids) {
    if (poids != null && poids <= 0) {
      throw ArgumentError.value(
        poids,
        'poids',
        'doit être strictement positif s\'il est fourni',
      );
    }
  }

  static void _validateId(String id, String name) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, name, 'ne doit pas être vide');
    }
  }

  @override
  List<Object?> get props => [
    type,
    date,
    maxPoints,
    poids,
    sousPeriodeId,
    periodeScolaireId,
    chapitreIds,
  ];
}
