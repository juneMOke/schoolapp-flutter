import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_closure_models.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_outbox_handler.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/presence/data/presence_schedule_reader.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_draft_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_history_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_day_writer.dart';
import 'package:school_app_flutter/features/attendances/data/repository/register/class_presence_mapper.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/register/class_presence_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/register/class_presence_month_reader.dart';

/// Le registre d'appel d'une classe, lu et écrit sur la tablette.
///
/// Le brouillon ([AttendanceDraftLocalDataSource]) porte les touches ; la
/// validation passe par [AttendanceDayWriter], qui écrit la session, ses
/// exceptions et l'agrégat à envoyer en une transaction — la même que celle
/// de l'appel d'avant la v2.
class ClassPresenceRepositoryImpl implements ClassPresenceRepository {
  final AttendanceLocalDataSource sessions;
  final AttendanceHistoryLocalDataSource history;
  final AttendanceDraftLocalDataSource drafts;
  final AttendanceClosureLocalDataSource closures;
  final ClassroomLocalDataSource roster;
  final PresenceScheduleReader scheduleReader;
  final OutboxDao outbox;
  final AttendanceDayWriter writer;
  final IdGenerator ids;
  final CurrentUserContext? currentUser;
  final SyncEngine? syncEngine;
  final Clock now;

  const ClassPresenceRepositoryImpl({
    required this.sessions,
    required this.history,
    required this.drafts,
    required this.closures,
    required this.roster,
    required this.scheduleReader,
    required this.outbox,
    required this.writer,
    required this.ids,
    this.currentUser,
    this.syncEngine,
    this.now = systemClock,
  });

  @override
  Future<Either<Failure, ClassPresenceDay>> loadDay(ClassDayKey key) => _guard(
    'Local attendance read failed',
    () async {
      final students = ClassPresenceMapper.students(
        await roster.getRoster(key.classroomId),
      );
      final session = await sessions.getSession(
        classroomId: key.classroomId,
        dateStr: key.day,
        academicYearId: key.academicYearId,
      );
      final editing = session == null || session.reopenedAt != null;
      final (sync, refusal) = await _sendState(key, session);
      final List<ClassPresenceLine> lines;
      if (editing) {
        final marks = {
          for (final row in await drafts.marksOf(
            classroomId: key.classroomId,
            dateStr: key.day,
            academicYearId: key.academicYearId,
          ))
            row.studentId: row,
        };
        lines = [
          for (final student in students)
            ClassPresenceMapper.fromDraft(student, marks[student.id]),
        ];
      } else {
        final records = {
          for (final row in await sessions.getDayRecords(
            classroomId: key.classroomId,
            dateStr: key.day,
            academicYearId: key.academicYearId,
          ))
            row.studentId: row,
        };
        lines = [
          for (final student in students)
            ClassPresenceMapper.fromSession(student, records[student.id], sync),
        ];
      }
      return ClassPresenceDay(
        classroomId: key.classroomId,
        academicYearId: key.academicYearId,
        day: key.day,
        lines: lines,
        hasSession: session != null,
        reopened: session?.reopenedAt != null,
        takenBy: session?.takenBy,
        lastSentAt: session?.updatedAt,
        sync: sync,
        refusal: refusal,
        monthClosed: await closures.isClosed(
          classroomId: key.classroomId,
          academicYearId: key.academicYearId,
          month: key.day.substring(0, 7),
        ),
        schedule: await scheduleReader.read(currentUser?.schoolId),
      );
    },
  );

  @override
  Future<Either<Failure, Unit>> saveMarks(
    ClassDayKey key,
    Map<String, PresenceMark<AbsenceReason>> marks,
  ) => _guard('Local attendance draft write failed', () async {
    final day = await loadDay(key);
    final current = {
      for (final line in day.fold((_) => <ClassPresenceLine>[], (d) => d.lines))
        line.student.id: line,
    };
    final nowMs = now();
    final rows = [
      for (final entry in marks.entries)
        if (current[entry.key] case final line?)
          ClassPresenceMapper.draftRow(
            line.withMark(entry.value),
            classroomId: key.classroomId,
            dateStr: key.day,
            academicYearId: key.academicYearId,
            updatedAt: nowMs,
          ),
    ];
    await drafts.putMarks(
      classroomId: key.classroomId,
      dateStr: key.day,
      academicYearId: key.academicYearId,
      marks: rows.nonNulls.toList(growable: false),
      removed: [
        for (final entry in marks.entries)
          if (!entry.value.status.isMarked) entry.key,
      ],
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> validateDay(
    ClassDayKey key,
    List<ClassPresenceLine> lines,
  ) async {
    try {
      final written = await writer.write(
        classroomId: key.classroomId,
        dateStr: key.day,
        academicYearId: key.academicYearId,
        covered: {for (final line in lines) line.student.id},
        lines: lines
            .map(ClassPresenceMapper.exception)
            .nonNulls
            .toList(growable: false),
      );
      if (written == AttendanceDayWrite.raced) {
        return const Left(
          StorageFailure(
            'Cet appel vient d\'être modifié ailleurs — rouvrez la journée '
            'pour repartir de l\'état à jour.',
          ),
        );
      }
      return const Right(unit);
    } catch (_) {
      return const Left(StorageFailure('Local attendance write failed'));
    }
  }

  @override
  Future<Either<Failure, Unit>> reopenDay(
    ClassDayKey key,
    List<ClassPresenceLine> lines,
  ) => _guard('Local attendance reopen failed', () async {
    final nowMs = now();
    await drafts.reopen(
      classroomId: key.classroomId,
      dateStr: key.day,
      academicYearId: key.academicYearId,
      reopenedAt: nowMs,
      marks: lines
          .map(
            (line) => ClassPresenceMapper.draftRow(
              line,
              classroomId: key.classroomId,
              dateStr: key.day,
              academicYearId: key.academicYearId,
              updatedAt: nowMs,
            ),
          )
          .nonNulls
          .toList(growable: false),
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> retryDay(ClassDayKey key) =>
      _guard('Local attendance retry failed', () async {
        await outbox.requeue(_entryId(key));
        final engine = syncEngine;
        if (engine != null) unawaited(engine.flush());
        return unit;
      });

  @override
  Future<Either<Failure, ClassPresenceMonth>> loadMonth(ClassMonthKey key) =>
      _guard(
        'Local attendance month read failed',
        () => ClassPresenceMonthReader(
          roster: roster,
          history: history,
          closures: closures,
        ).read(key),
      );

  @override
  Future<Either<Failure, Unit>> closeMonth(ClassMonthKey key) => _guard(
    'Local attendance closure failed',
    () async {
      final gestureId = ids.newId();
      final nowMs = now();
      final at = DateTime.fromMillisecondsSinceEpoch(
        nowMs,
        isUtc: true,
      ).toIso8601String();
      final closure = AttendanceClosureRequestModel(
        gestureId: gestureId,
        classroomId: key.classroomId,
        academicYearId: key.academicYearId,
        month: key.month,
        clientRecordedAt: at,
        authorId: currentUser?.uid,
      );
      await closures.record(
        gestureId: gestureId,
        classroomId: key.classroomId,
        academicYearId: key.academicYearId,
        month: key.month,
        closedAt: at,
        // Un geste = une entrée, sous son propre identifiant : deux
        // clôtures ne fusionnent jamais.
        entry: OutboxEntry(
          id: gestureId,
          aggregateType: kAttendanceClosureAggregateType,
          aggregateId: '${key.classroomId}|${key.month}|${key.academicYearId}',
          operation: OutboxOperation.upsert,
          payload: closure.toJsonString(),
          createdAt: nowMs,
        ),
      );
      final engine = syncEngine;
      if (engine != null) unawaited(engine.flush());
      return unit;
    },
  );

  /// Où en est l'envoi de l'appel : au serveur, en file, ou refusé (avec la
  /// raison écrite par le serveur).
  Future<(RecordSyncState, String?)> _sendState(
    ClassDayKey key,
    AttendanceSessionRow? session,
  ) async {
    if (session == null || session.isSynced) {
      return (RecordSyncState.synced, null);
    }
    final entry = await outbox.byId(_entryId(key));
    if (entry != null && entry.status == OutboxStatus.syncError) {
      return (RecordSyncState.failed, entry.lastError);
    }
    return (RecordSyncState.pending, null);
  }

  static String _entryId(ClassDayKey key) => AttendanceDayWriter.outboxEntryId(
    key.classroomId,
    key.day,
    key.academicYearId,
  );

  static Future<Either<Failure, T>> _guard<T>(
    String message,
    Future<T> Function() body,
  ) async {
    try {
      return Right(await body());
    } catch (_) {
      return Left(StorageFailure(message));
    }
  }
}
