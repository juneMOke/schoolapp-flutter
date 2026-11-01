import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';

/// Une ligne d'envoi. `updatedAt` est le jeton du dernier-écrit-gagne, et
/// `valeur` nulle vide la cellule.
class CoteLineDto {
  final CoteCellKey key;
  final double? valeur;
  final int updatedAtMs;

  const CoteLineDto({
    required this.key,
    required this.valeur,
    required this.updatedAtMs,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'studentId': key.studentId,
    'coursId': key.coursId,
    'sousPeriodeId': key.examen ? null : key.colonneId,
    'periodeScolaireId': key.examen ? key.colonneId : null,
    'valeur': valeur,
    'updatedAt': EpochIsoHelper.toIso(updatedAtMs),
  };
}

class CotesPushRequest {
  final String? authorId;
  final List<CoteLineDto> cotes;

  const CotesPushRequest({required this.authorId, required this.cotes});

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (authorId != null) 'authorId': authorId,
    'cotes': cotes.map((c) => c.toJson()).toList(),
  };
}

enum CoteOutcome {
  applied,
  superseded,
  rejected;

  static CoteOutcome? tryParse(Object? value) => switch (value) {
    'APPLIED' => CoteOutcome.applied,
    'SUPERSEDED' => CoteOutcome.superseded,
    'REJECTED' => CoteOutcome.rejected,
    _ => null,
  };
}

/// Le résultat d'une ligne. `valeur` porte l'état du serveur : sur `SUPERSEDED`,
/// c'est la valeur qui a gagné, pas celle qu'on a envoyée.
class CoteResultDto {
  final String studentId;
  final String coursId;
  final String colonneId;
  final CoteOutcome outcome;
  final String? reason;
  final double? valeur;
  final int? updatedAtMs;

  const CoteResultDto({
    required this.studentId,
    required this.coursId,
    required this.colonneId,
    required this.outcome,
    this.reason,
    this.valeur,
    this.updatedAtMs,
  });

  /// `null` si la ligne est inexploitable : la cellule reste en attente et le
  /// lot sera rejoué, plutôt que de l'acquitter sur un malentendu.
  static CoteResultDto? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final studentId = raw['studentId'];
    final coursId = raw['coursId'];
    final colonneId = raw['sousPeriodeId'] ?? raw['periodeScolaireId'];
    final outcome = CoteOutcome.tryParse(raw['outcome']);
    if (studentId is! String ||
        coursId is! String ||
        colonneId is! String ||
        outcome == null) {
      return null;
    }
    final valeur = raw['valeur'];
    return CoteResultDto(
      studentId: studentId,
      coursId: coursId,
      colonneId: colonneId,
      outcome: outcome,
      reason: raw['reason'] as String?,
      valeur: valeur is num ? valeur.toDouble() : null,
      updatedAtMs: EpochIsoHelper.tryToEpochMs(raw['updatedAt']),
    );
  }
}

class CotesPushResponse {
  final List<CoteResultDto> results;

  const CotesPushResponse({required this.results});

  factory CotesPushResponse.fromJson(Map<String, dynamic> json) =>
      CotesPushResponse(
        results: [
          for (final raw in (json['results'] as List<dynamic>?) ?? const [])
            ?CoteResultDto.tryParse(raw),
        ],
      );
}
