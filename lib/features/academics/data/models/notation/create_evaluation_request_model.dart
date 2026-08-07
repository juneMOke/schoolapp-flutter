import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

/// Corps JSON du POST de création d'évaluation.
///
/// [toJson] applique les règles d'émission conditionnelle exigées par le
/// contrat :
/// - `type` en valeur wire majuscule (INTERRO / DEVOIR / EXAMEN) ;
/// - `date` au format date-only `yyyy-MM-dd` ;
/// - `poids` **émis uniquement s'il est non nul** (sinon défaut backend = 1) ;
/// - un **seul** id temporel émis (`sousPeriodeId` XOR `periodeScolaireId`) ;
/// - `chapitreIds` **omis s'il est vide**.
class CreateEvaluationRequestModel {
  /// Valeur wire majuscule (INTERRO / DEVOIR / EXAMEN).
  final String type;
  final DateTime date;
  final double maxPoints;
  final int? poids;
  final String? sousPeriodeId;
  final String? periodeScolaireId;
  final List<String> chapitreIds;

  const CreateEvaluationRequestModel({
    required this.type,
    required this.date,
    required this.maxPoints,
    this.poids,
    this.sousPeriodeId,
    this.periodeScolaireId,
    this.chapitreIds = const [],
  });

  /// Construit le corps depuis l'objet domaine, en convertissant le type en
  /// valeur wire. Les ids temporels sont déjà exclusifs par construction côté
  /// [CreateEvaluationRequest].
  factory CreateEvaluationRequestModel.fromDomain(
    CreateEvaluationRequest request,
  ) => CreateEvaluationRequestModel(
    type: request.type.toApiValue(),
    date: request.date,
    maxPoints: request.maxPoints,
    poids: request.poids,
    sousPeriodeId: request.sousPeriodeId,
    periodeScolaireId: request.periodeScolaireId,
    chapitreIds: request.chapitreIds,
  );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
      'date': DateOnlyJsonHelper.toJson(date),
      'maxPoints': maxPoints,
    };
    // poids : seulement s'il est fourni (sinon le backend défaut à 1).
    if (poids != null) json['poids'] = poids;
    // Rattachement temporel exclusif : un seul des deux ids non nul.
    if (sousPeriodeId != null) json['sousPeriodeId'] = sousPeriodeId;
    if (periodeScolaireId != null) {
      json['periodeScolaireId'] = periodeScolaireId;
    }
    // Relation n-n optionnelle : omise si vide.
    if (chapitreIds.isNotEmpty) json['chapitreIds'] = chapitreIds;
    return json;
  }
}
