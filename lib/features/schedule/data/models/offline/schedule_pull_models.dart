// DTOs de pull delta de l'emploi du temps (contrat PLAN_notes_cours_offline,
// `GET /sync/schedule/time-slots` et `GET /sync/schedule/sessions`). Pages
// keyset (ADR-008/009). Réponses serveur (fromJson) → lignes locales SYNCED à
// l'application. Référence read-only : aucun régime d'écriture.

import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_recurring_session_row.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_time_slot_row.dart';

/// Mappe une liste serveur en **tolérant les lignes malformées** : une ligne
/// dont le `fromJson` lève est ignorée au lieu de figer le curseur (anti
/// poison-page). La ligne écartée réapparaîtra au prochain delta une fois
/// corrigée côté serveur.
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

/// ISO-8601 UTC → epoch ms. Un ISO **naïf** (sans `Z` ni offset) est ré-ancré en
/// UTC (le wire est UTC par contrat ; sinon l'instant serait décalé du fuseau
/// de l'appareil).
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

// ── Time slots ────────────────────────────────────────────────────────────────

class TimeSlotDeltaDto {
  final String id;
  final int slotOrder;
  final String startTime;
  final String endTime;
  final String? label;
  final String serverUpdatedAt;

  const TimeSlotDeltaDto({
    required this.id,
    required this.slotOrder,
    required this.startTime,
    required this.endTime,
    this.label,
    required this.serverUpdatedAt,
  });

  factory TimeSlotDeltaDto.fromJson(Map<String, dynamic> j) => TimeSlotDeltaDto(
    id: j['id'] as String,
    slotOrder: (j['slotOrder'] as num?)?.toInt() ?? 0,
    startTime: j['startTime'] as String,
    endTime: j['endTime'] as String,
    label: j['label'] as String?,
    serverUpdatedAt: j['serverUpdatedAt'] as String,
  );

  RefTimeSlotRow toLocalRow(int syncedAt) => RefTimeSlotRow(
    id: id,
    slotOrder: slotOrder,
    startTime: startTime,
    endTime: endTime,
    label: label,
    serverUpdatedAt: _isoToMs(serverUpdatedAt),
    syncedAt: syncedAt,
  );
}

class TimeSlotPageDto implements KeysetPageDto<TimeSlotDeltaDto> {
  @override
  final List<TimeSlotDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const TimeSlotPageDto({required this.items, required this.page});

  factory TimeSlotPageDto.fromJson(Map<String, dynamic> j) => TimeSlotPageDto(
    items: _lenientList(j['items'], TimeSlotDeltaDto.fromJson),
    page: KeysetPageEnvelope.fromJson(j),
  );
}

// ── Recurring sessions ────────────────────────────────────────────────────────

class RecurringSessionDeltaDto {
  final String id;
  final String academicYearId;
  final String coursId;
  final String timeSlotId;
  final String dayOfWeek;
  final String? room;
  final String teacherId;
  final String classroomId;
  final String teacherLabel;
  final String classroomLabel;
  final String subjectLabel;
  final String serverUpdatedAt;

  const RecurringSessionDeltaDto({
    required this.id,
    required this.academicYearId,
    required this.coursId,
    required this.timeSlotId,
    required this.dayOfWeek,
    this.room,
    required this.teacherId,
    required this.classroomId,
    required this.teacherLabel,
    required this.classroomLabel,
    required this.subjectLabel,
    required this.serverUpdatedAt,
  });

  factory RecurringSessionDeltaDto.fromJson(Map<String, dynamic> j) =>
      RecurringSessionDeltaDto(
        id: j['id'] as String,
        academicYearId: j['academicYearId'] as String,
        coursId: j['coursId'] as String,
        timeSlotId: j['timeSlotId'] as String,
        dayOfWeek: j['dayOfWeek'] as String,
        room: j['room'] as String?,
        teacherId: j['teacherId'] as String,
        classroomId: j['classroomId'] as String,
        teacherLabel: j['teacherLabel'] as String,
        classroomLabel: j['classroomLabel'] as String,
        subjectLabel: j['subjectLabel'] as String,
        serverUpdatedAt: j['serverUpdatedAt'] as String,
      );

  RefRecurringSessionRow toLocalRow(int syncedAt) => RefRecurringSessionRow(
    id: id,
    academicYearId: academicYearId,
    coursId: coursId,
    timeSlotId: timeSlotId,
    dayOfWeek: dayOfWeek,
    room: room,
    teacherId: teacherId,
    classroomId: classroomId,
    teacherLabel: teacherLabel,
    classroomLabel: classroomLabel,
    subjectLabel: subjectLabel,
    serverUpdatedAt: _isoToMs(serverUpdatedAt),
    syncedAt: syncedAt,
  );
}

class RecurringSessionPageDto
    implements KeysetPageDto<RecurringSessionDeltaDto> {
  @override
  final List<RecurringSessionDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const RecurringSessionPageDto({required this.items, required this.page});

  factory RecurringSessionPageDto.fromJson(Map<String, dynamic> j) =>
      RecurringSessionPageDto(
        items: _lenientList(j['items'], RecurringSessionDeltaDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}
