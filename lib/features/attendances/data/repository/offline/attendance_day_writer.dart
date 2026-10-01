import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_absence_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_line_wire.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';

/// Type d'agrégat d'outbox de l'appel (routage vers `AttendanceOutboxHandler`).
const String kAttendanceAggregateType = 'ATTENDANCE';

/// Une exception de l'appel à écrire : un retard ou une absence.
class AttendanceDayLine extends Equatable {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;

  /// Genre sur le fil (`MALE`, `FEMALE`, `OTHER`).
  final String studentGender;

  /// [PresenceStatus.late] ou [PresenceStatus.absent].
  final PresenceStatus status;

  /// `HH:mm`, retard seulement.
  final String? arrivalTime;
  final int? lateMinutes;

  /// Motif codé (`SICKNESS`…), `null` = non justifiée.
  final String? absenceReason;
  final String? absenceReasonNote;

  const AttendanceDayLine({
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    required this.studentGender,
    required this.status,
    this.studentMiddleName,
    this.arrivalTime,
    this.lateMinutes,
    this.absenceReason,
    this.absenceReasonNote,
  });

  bool get _isLate => status == PresenceStatus.late;

  /// La ligne en base dit-elle déjà la même chose ? Une ligne inchangée garde
  /// son horodatage : la réestamper lui ferait gagner un arbitrage LWW qu'elle
  /// ne doit pas gagner.
  bool sameAs(AttendanceRecordRow row) =>
      row.presenceStatus == status &&
      row.arrivalTime == (_isLate ? arrivalTime : null) &&
      row.lateMinutes == (_isLate ? lateMinutes : null) &&
      row.absenceReason == absenceReason &&
      row.absenceReasonNote == absenceReasonNote;

  @override
  List<Object?> get props => [
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    status,
    arrivalTime,
    lateMinutes,
    absenceReason,
    absenceReasonNote,
  ];
}

/// L'issue d'une écriture d'appel.
enum AttendanceDayWrite {
  written,

  /// Une écriture concurrente a pris la main : rien n'a été écrit ni enfilé.
  raced,
}

/// Écrit l'appel d'une classe pour un jour : la session (racine d'agrégat),
/// ses exceptions (retards et absences), l'agrégat exhaustif à envoyer et son
/// entrée d'outbox — dans **une** transaction, qui vide aussi le brouillon du
/// jour et lève une réouverture (`AttendanceLocalDataSource.confirmDailyAttendance`).
///
/// Sert la validation d'un appel et la justification après coup d'un appel
/// validé : les deux renvoient l'agrégat entier, que le serveur réconcilie par
/// différence.
class AttendanceDayWriter {
  final AttendanceLocalDataSource localDataSource;
  final ClassroomLocalDataSource rosterDataSource;
  final IdGenerator idGenerator;
  final CurrentUserContext? currentUser;
  final SyncEngine? syncEngine;
  final Clock now;

  const AttendanceDayWriter({
    required this.localDataSource,
    required this.rosterDataSource,
    required this.idGenerator,
    this.currentUser,
    this.syncEngine,
    this.now = systemClock,
  });

  /// Clé d'idempotence / id déterministe d'outbox pour un appel.
  static String outboxKey(
    String classroomId,
    String dateStr,
    String academicYearId,
  ) => '$classroomId|$dateStr|$academicYearId';

  static String outboxEntryId(
    String classroomId,
    String dateStr,
    String academicYearId,
  ) =>
      '$kAttendanceAggregateType:${outboxKey(classroomId, dateStr, academicYearId)}';

  /// Horloge **monotone** par session : `clientUpdatedAt` doit toujours être
  /// strictement supérieur à l'`updated_at` déjà en base. Le serveur arbitre
  /// en STRICT et n'écrit rien quand il perd ; l'`updated_at` local vient
  /// souvent d'un pull au temps serveur, en avance sur une tablette qui
  /// retarde : sans cette garde, la correction serait sautée des deux côtés
  /// avec un « succès » à l'écran.
  static int monotonic(int nowMs, int localUpdatedAt) =>
      nowMs > localUpdatedAt ? nowMs : localUpdatedAt + 1;

  /// [lines] = les retards et absences ; [covered] = tous les élèves dont
  /// l'appelant connaît l'état (présents compris). Une exception locale d'un
  /// élève hors de [covered] est renvoyée telle quelle, jamais effacée.
  Future<AttendanceDayWrite> write({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
    required List<AttendanceDayLine> lines,
    required Set<String> covered,
  }) async {
    // Id de session STABLE (id = transport, clé naturelle = vérité).
    final existingSession = await localDataSource.getSession(
      classroomId: classroomId,
      dateStr: dateStr,
      academicYearId: academicYearId,
    );
    final sessionId = existingSession?.id ?? idGenerator.newId();
    final nowMs = monotonic(now(), existingSession?.updatedAt ?? 0);
    String iso(int ms) =>
        DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

    // `taken_at` = heure du PREMIER appel ; `taken_by` repoussé tel quel (le
    // serveur garde le libellé existant quand le message n'en porte pas).
    final takenAtMs = existingSession?.takenAt ?? nowMs;
    final session = AttendanceSessionRow(
      id: sessionId,
      classroomId: classroomId,
      attendanceDate: dateStr,
      academicYearId: academicYearId,
      takenAt: takenAtMs,
      takenBy: existingSession?.takenBy,
      updatedAt: nowMs,
      syncStatus: SyncState.pendingSync.dbValue,
    );

    final existingRows = {
      for (final row in await localDataSource.getDayRecords(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: academicYearId,
      ))
        row.studentId: row,
    };
    final rows = [
      for (final line in lines)
        _row(
          line,
          existingRows[line.studentId],
          nowMs,
          classroomId: classroomId,
          dateStr: dateStr,
          academicYearId: academicYearId,
        ),
      ...await _preserved(
        classroomId: classroomId,
        existing: existingRows.values,
        covered: {...covered, for (final line in lines) line.studentId},
      ),
    ];

    final aggregate = AttendanceAggregateRequestModel(
      authorId: currentUser?.uid, // estampillage authorId (ADR-010 D-05)
      session: AttendanceSessionInputModel(
        id: sessionId,
        classroomId: classroomId,
        attendanceDate: dateStr,
        academicYearId: academicYearId,
        takenAt: iso(takenAtMs),
        takenBy: existingSession?.takenBy,
        updatedAt: iso(nowMs),
      ),
      absences: [
        for (final row in rows)
          AttendanceAbsenceInputModel(
            id: row.id,
            studentId: row.studentId,
            // Toujours posé : un statut manquant garderait celui de la base.
            status: row.status ?? AttendanceLineWire.absent,
            arrivalTime: row.arrivalTime,
            lateMinutes: row.lateMinutes,
            absenceReason: row.absenceReason,
            absenceReasonNote: row.absenceReasonNote,
            updatedAt: iso(row.updatedAt),
          ),
      ],
    );

    final key = outboxKey(classroomId, dateStr, academicYearId);
    final persisted = await localDataSource.confirmDailyAttendance(
      session: session,
      absentRows: rows,
      outboxEntry: OutboxEntry(
        // Id déterministe → un nouvel envoi du même jour REMPLACE l'entrée.
        id: '$kAttendanceAggregateType:$key',
        aggregateType: kAttendanceAggregateType,
        aggregateId: key,
        operation: OutboxOperation.upsert,
        payload: aggregate.toJsonString(),
        createdAt: nowMs,
      ),
    );
    if (!persisted) return AttendanceDayWrite.raced;
    final engine = syncEngine;
    if (engine != null) unawaited(engine.flush());
    return AttendanceDayWrite.written;
  }

  AttendanceRecordRow _row(
    AttendanceDayLine line,
    AttendanceRecordRow? existing,
    int nowMs, {
    required String classroomId,
    required String dateStr,
    required String academicYearId,
  }) {
    final late = line.status == PresenceStatus.late;
    final unchanged = existing != null && line.sameAs(existing);
    return AttendanceRecordRow(
      id: existing?.id ?? idGenerator.newId(),
      studentId: line.studentId,
      studentFirstName: line.studentFirstName,
      studentLastName: line.studentLastName,
      studentMiddleName: line.studentMiddleName,
      studentGender: line.studentGender,
      classroomId: classroomId,
      attendanceDate: dateStr,
      academicYearId: academicYearId,
      present: late,
      status: AttendanceLineWire.write(line.status),
      arrivalTime: late ? line.arrivalTime : null,
      lateMinutes: late ? line.lateMinutes : null,
      absenceReason: line.absenceReason,
      absenceReasonNote: line.absenceReasonNote,
      updatedAt: unchanged ? existing.updatedAt : nowMs,
      syncStatus: SyncState.pendingSync.dbValue,
    );
  }

  /// Les exceptions locales du jour que [covered] ne porte pas, pour les
  /// élèves encore membres ACTIFS de la classe : le serveur réconcilie par
  /// différence, une exception omise serait détruite sans que personne ne
  /// l'ait voulu. Un élève sorti de la classe n'est jamais réinjecté : le
  /// serveur valide le roster actif AVANT tout arbitrage et refuserait
  /// l'agrégat entier (422 terminal, journée perdue).
  Future<List<AttendanceRecordRow>> _preserved({
    required String classroomId,
    required Iterable<AttendanceRecordRow> existing,
    required Set<String> covered,
  }) async {
    final active = {
      for (final member in await rosterDataSource.getRoster(classroomId))
        member.studentId,
    };
    return [
      for (final row in existing)
        if (!covered.contains(row.studentId) &&
            active.contains(row.studentId) &&
            row.presenceStatus.isIncident)
          row,
    ];
  }
}
