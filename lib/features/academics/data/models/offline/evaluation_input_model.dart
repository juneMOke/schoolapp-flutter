import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';

/// Volet `evaluation` de l'enveloppe poussée au `/sync` (régime A, insert-only).
/// Aligné sur le contrat de création online : `type` en valeur wire majuscule,
/// `date` au format date-only `yyyy-MM-dd`, `poids` émis seulement s'il est non
/// nul, rattachement temporel **exclusif** (`sousPeriodeId` XOR `periodeScolaireId`).
/// `chapitreIds` reste `[]` en V1 (chapitres hors périmètre offline) → omis.
class EvaluationInputModel extends Equatable {
  final String id;
  final String coursId;
  final String type;
  final DateTime date;
  final double maxPoints;
  final int poids;
  final String? sousPeriodeId;
  final String? periodeScolaireId;

  const EvaluationInputModel({
    required this.id,
    required this.coursId,
    required this.type,
    required this.date,
    required this.maxPoints,
    required this.poids,
    this.sousPeriodeId,
    this.periodeScolaireId,
  });

  /// Construit le volet depuis la ligne locale. `evalDate` (epoch ms, ancré UTC
  /// à minuit à l'écriture) → `DateTime` UTC.
  factory EvaluationInputModel.fromRow(EvaluationRow row) =>
      EvaluationInputModel(
        id: row.id,
        coursId: row.coursId,
        type: row.type,
        date: DateTime.fromMillisecondsSinceEpoch(row.evalDate, isUtc: true),
        maxPoints: row.maxPoints,
        poids: row.poids,
        sousPeriodeId: row.sousPeriodeId,
        periodeScolaireId: row.periodeScolaireId,
      );

  factory EvaluationInputModel.fromJson(Map<String, dynamic> json) =>
      EvaluationInputModel(
        id: json['id'] as String,
        coursId: json['coursId'] as String,
        type: json['type'] as String,
        date: DateOnlyJsonHelper.fromJson(json['date'] as String),
        maxPoints: (json['maxPoints'] as num).toDouble(),
        poids: (json['poids'] as num?)?.toInt() ?? 1,
        sousPeriodeId: json['sousPeriodeId'] as String?,
        periodeScolaireId: json['periodeScolaireId'] as String?,
      );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'coursId': coursId,
      'type': type,
      'date': DateOnlyJsonHelper.toJson(date),
      'maxPoints': maxPoints,
    };
    if (poids != 0) json['poids'] = poids;
    if (sousPeriodeId != null) json['sousPeriodeId'] = sousPeriodeId;
    if (periodeScolaireId != null) {
      json['periodeScolaireId'] = periodeScolaireId;
    }
    return json;
  }

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
  ];
}
