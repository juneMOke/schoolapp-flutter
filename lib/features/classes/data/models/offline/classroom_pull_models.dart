// Page keyset des classes (contrat classroom-offline V1, re-contracté
// 2026-07-27, `GET /sync/classrooms`). Réutilise `ClassroomDto` (transport +
// ligne sqflite inchangés) — seule l'enveloppe de pagination change.

import 'package:school_app_flutter/features/classes/data/models/offline/classroom_dto.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

/// Mappe une liste serveur en **tolérant les lignes malformées** : une ligne
/// dont le `fromJson` lève est ignorée au lieu de figer le curseur (anti
/// poison-page). Elle réapparaîtra au prochain delta une fois corrigée serveur.
List<T> _lenientList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  final out = <T>[];
  for (final e in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(parse(e as Map<String, dynamic>));
    } catch (_) {
      // Ligne écartée : le curseur avance, la ressource ne fige pas.
    }
  }
  return out;
}

/// Page keyset de classes.
class ClassroomPageDto implements KeysetPageDto<ClassroomDto> {
  @override
  final List<ClassroomDto> items;
  @override
  final KeysetPageEnvelope page;

  const ClassroomPageDto({required this.items, required this.page});

  factory ClassroomPageDto.fromJson(Map<String, dynamic> j) => ClassroomPageDto(
    items: _lenientList(j['items'], ClassroomDto.fromJson),
    page: KeysetPageEnvelope.fromJson(j),
  );
}
