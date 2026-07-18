// DTOs de pull delta de la Présence (contrat openapi_attendance_sync 1.2.0,
// `GET /sync/attendance`). Sessions paginées keyset, absences imbriquées.
// Réponses serveur (fromJson) → converties en lignes locales à l'application.

import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_row.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

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

int? _isoToMs(String? iso) =>
    iso == null ? null : DateTime.tryParse(iso)?.millisecondsSinceEpoch;

/// Agrégat local prêt à appliquer : la session + ses exceptions (déjà résolues
/// en lignes locales SYNCED). L'id de session est celui du serveur (transport) ;
/// le DAO conserve l'id local si la clé naturelle existe déjà.
class PulledAttendanceSession {
  final AttendanceSessionRow session;
  final List<AttendanceRecordRow> absences;

  const PulledAttendanceSession({
    required this.session,
    required this.absences,
  });
}

/// Une exception (absence) imbriquée dans une session pullée.
class AbsenceDeltaDto {
  final String id;
  final String studentId;
  final String? studentFirstName;
  final String? studentLastName;
  final String? studentMiddleName;
  final String? studentGender;
  final String? absenceReason;
  final String? absenceReasonNote;
  final String? updatedAt;

  const AbsenceDeltaDto({
    required this.id,
    required this.studentId,
    this.studentFirstName,
    this.studentLastName,
    this.studentMiddleName,
    this.studentGender,
    this.absenceReason,
    this.absenceReasonNote,
    this.updatedAt,
  });

  factory AbsenceDeltaDto.fromJson(Map<String, dynamic> j) => AbsenceDeltaDto(
    id: j['id'] as String,
    studentId: j['studentId'] as String,
    studentFirstName: j['studentFirstName'] as String?,
    studentLastName: j['studentLastName'] as String?,
    studentMiddleName: j['studentMiddleName'] as String?,
    studentGender: j['studentGender'] as String?,
    absenceReason: j['absenceReason'] as String?,
    absenceReasonNote: j['absenceReasonNote'] as String?,
    updatedAt: j['updatedAt'] as String?,
  );

  AttendanceRecordRow toLocalRow({
    required String classroomId,
    required String attendanceDate,
    required String academicYearId,
    required int syncedAt,
  }) => AttendanceRecordRow(
    id: id,
    studentId: studentId,
    studentFirstName: studentFirstName ?? '',
    studentLastName: studentLastName ?? '',
    studentMiddleName: studentMiddleName,
    studentGender: studentGender ?? 'OTHER',
    classroomId: classroomId,
    attendanceDate: attendanceDate,
    academicYearId: academicYearId,
    present: false,
    absenceReason: absenceReason,
    absenceReasonNote: absenceReasonNote,
    updatedAt: _isoToMs(updatedAt) ?? syncedAt,
    syncStatus: SyncState.synced.dbValue,
    syncedAt: syncedAt,
  );
}

/// Une session pullée (racine d'agrégat) avec ses absences imbriquées.
class AttendanceSessionDeltaDto {
  final String id;
  final String classroomId;
  final String attendanceDate;
  final String academicYearId;
  final int? expectedCount;
  final String? takenAt;
  final String? takenBy;
  final String updatedAt;
  final String? serverUpdatedAt;
  final List<AbsenceDeltaDto> absences;

  const AttendanceSessionDeltaDto({
    required this.id,
    required this.classroomId,
    required this.attendanceDate,
    required this.academicYearId,
    this.expectedCount,
    this.takenAt,
    this.takenBy,
    required this.updatedAt,
    this.serverUpdatedAt,
    this.absences = const [],
  });

  factory AttendanceSessionDeltaDto.fromJson(Map<String, dynamic> j) =>
      AttendanceSessionDeltaDto(
        id: j['id'] as String,
        classroomId: j['classroomId'] as String,
        attendanceDate: j['attendanceDate'] as String,
        academicYearId: j['academicYearId'] as String,
        expectedCount: (j['expectedCount'] as num?)?.toInt(),
        takenAt: j['takenAt'] as String?,
        takenBy: j['takenBy'] as String?,
        updatedAt: j['updatedAt'] as String,
        serverUpdatedAt: j['serverUpdatedAt'] as String?,
        absences: _lenientList(j['absences'], AbsenceDeltaDto.fromJson),
      );

  PulledAttendanceSession toPulled(int syncedAt) => PulledAttendanceSession(
    session: AttendanceSessionRow(
      id: id,
      classroomId: classroomId,
      attendanceDate: attendanceDate,
      academicYearId: academicYearId,
      expectedCount: expectedCount,
      takenAt: _isoToMs(takenAt),
      takenBy: takenBy,
      updatedAt: _isoToMs(updatedAt) ?? syncedAt,
      serverUpdatedAt: serverUpdatedAt,
      syncStatus: SyncState.synced.dbValue,
      syncedAt: syncedAt,
    ),
    absences: absences
        .map(
          (a) => a.toLocalRow(
            classroomId: classroomId,
            attendanceDate: attendanceDate,
            academicYearId: academicYearId,
            syncedAt: syncedAt,
          ),
        )
        .toList(growable: false),
  );
}

/// Page keyset de sessions (absences imbriquées).
class AttendanceSessionPageDto
    implements KeysetPageDto<AttendanceSessionDeltaDto> {
  @override
  final List<AttendanceSessionDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const AttendanceSessionPageDto({required this.items, required this.page});

  factory AttendanceSessionPageDto.fromJson(Map<String, dynamic> j) =>
      AttendanceSessionPageDto(
        items: _lenientList(j['items'], AttendanceSessionDeltaDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}
