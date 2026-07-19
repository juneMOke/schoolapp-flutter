// DTOs de pull delta des cours (contrat PLAN_notes_cours_offline,
// `GET /sync/academics/cours?classroomId=`). Page keyset par classe (ADR-008/009).
// Référence read-only : aucun régime d'écriture.

import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_row.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

/// Mappe une liste serveur en **tolérant les lignes malformées** (anti
/// poison-page) : une ligne dont le `fromJson` lève est ignorée, le curseur
/// avance quand même.
List<T> _lenientList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  final out = <T>[];
  for (final e in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(parse(e as Map<String, dynamic>));
    } catch (_) {
      // Ligne écartée : la ressource ne fige pas.
    }
  }
  return out;
}

int? _isoToMs(String? iso) {
  if (iso == null) return null;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return null;
  final utc = parsed.isUtc
      ? parsed
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
  return utc.millisecondsSinceEpoch;
}

class CoursDeltaDto {
  final String id;
  final String classroomId;
  final String ligneBaremeId;
  final String? teacherId;
  final String serverUpdatedAt;

  const CoursDeltaDto({
    required this.id,
    required this.classroomId,
    required this.ligneBaremeId,
    this.teacherId,
    required this.serverUpdatedAt,
  });

  factory CoursDeltaDto.fromJson(Map<String, dynamic> j) => CoursDeltaDto(
    id: j['id'] as String,
    classroomId: j['classroomId'] as String,
    ligneBaremeId: j['ligneBaremeId'] as String,
    teacherId: j['teacherId'] as String?,
    serverUpdatedAt: j['serverUpdatedAt'] as String,
  );

  RefCoursRow toLocalRow(int syncedAt) => RefCoursRow(
    id: id,
    classroomId: classroomId,
    ligneBaremeId: ligneBaremeId,
    teacherId: teacherId,
    serverUpdatedAt: _isoToMs(serverUpdatedAt),
    syncedAt: syncedAt,
  );
}

class CoursPageDto implements KeysetPageDto<CoursDeltaDto> {
  @override
  final List<CoursDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const CoursPageDto({required this.items, required this.page});

  factory CoursPageDto.fromJson(Map<String, dynamic> j) => CoursPageDto(
    items: _lenientList(j['items'], CoursDeltaDto.fromJson),
    page: KeysetPageEnvelope.fromJson(j),
  );
}
