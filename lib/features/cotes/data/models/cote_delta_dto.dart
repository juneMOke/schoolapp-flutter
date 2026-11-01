import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';

/// Une cote du flux de la tablette. `valeur` nulle : la cote a été vidée.
class CoteDeltaDto {
  final String studentId;
  final String coursId;
  final String colonneId;
  final bool examen;
  final double? valeur;
  final int? updatedAtMs;

  const CoteDeltaDto({
    required this.studentId,
    required this.coursId,
    required this.colonneId,
    required this.examen,
    this.valeur,
    this.updatedAtMs,
  });

  /// `null` si la ligne est inutilisable : elle est sautée, le curseur avance.
  static CoteDeltaDto? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final studentId = raw['studentId'];
    final coursId = raw['coursId'];
    final sousPeriodeId = raw['sousPeriodeId'];
    final colonneId = sousPeriodeId ?? raw['periodeScolaireId'];
    if (studentId is! String || coursId is! String || colonneId is! String) {
      return null;
    }
    final valeur = raw['valeur'];
    return CoteDeltaDto(
      studentId: studentId,
      coursId: coursId,
      colonneId: colonneId,
      examen: sousPeriodeId == null,
      valeur: valeur is num ? valeur.toDouble() : null,
      updatedAtMs: EpochIsoHelper.tryToEpochMs(raw['updatedAt']),
    );
  }
}

class CotePageDto implements KeysetPageDto<CoteDeltaDto> {
  @override
  final List<CoteDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const CotePageDto({required this.items, required this.page});

  factory CotePageDto.fromJson(Map<String, dynamic> json) => CotePageDto(
    items: [
      for (final raw in (json['items'] as List<dynamic>?) ?? const [])
        ?CoteDeltaDto.tryParse(raw),
    ],
    page: KeysetPageEnvelope.fromJson(json),
  );
}
