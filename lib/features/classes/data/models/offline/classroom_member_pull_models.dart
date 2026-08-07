// Page keyset du roster (contrat classroom-offline V1, re-contracté
// 2026-07-27, `GET /sync/classroom-members`). Réutilise `ClassroomMemberDto`
// (transport + ligne sqflite inchangés) — seule l'enveloppe de pagination
// change. Ressource **indépendante** du flux `classrooms` (curseur séparé).

import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
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

/// Page keyset de membres de roster.
class ClassroomMemberPageDto implements KeysetPageDto<ClassroomMemberDto> {
  @override
  final List<ClassroomMemberDto> items;
  @override
  final KeysetPageEnvelope page;

  const ClassroomMemberPageDto({required this.items, required this.page});

  factory ClassroomMemberPageDto.fromJson(Map<String, dynamic> j) =>
      ClassroomMemberPageDto(
        items: _lenientList(j['items'], ClassroomMemberDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}
