import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_closure_models.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_outbox_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/presence/data/presence_schedule_reader.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
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
import 'package:school_app_flutter/features/attendances/data/repository/register/class_presence_day_reader.dart';

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

  ClassPresenceDayReader get _days => ClassPresenceDayReader(
    sessions: sessions,
    drafts: drafts,
    closures: closures,
    roster: roster,
    scheduleReader: scheduleReader,
    outbox: outbox,
    currentUser: currentUser,
  );

  @override
  Future<Either<Failure, ClassPresenceDay>> loadDay(ClassDayKey key) =>
      _guard('Local attendance read failed', () => _days.read(key));

  @override
  Future<Either<Failure, Unit>> saveMarks(
    ClassDayKey key,
    Map<String, PresenceMark<AbsenceReason>> marks,
  ) => _guard('Local attendance draft write failed', () async {
    final day = await _days.read(key);
    final current = {for (final line in day.lines) line.student.id: line};
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
            // Sur un appel rouvert, « à pointer » masque la ligne en base.
            keepNone: day.reopened,
          ),
    ];
    await drafts.putMarks(
      classroomId: key.classroomId,
      dateStr: key.day,
      academicYearId: key.academicYearId,
      marks: rows.nonNulls.toList(growable: false),
      removed: [
        if (!day.reopened)
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
      final sent = await _freshUntouched(key, lines);
      final written = await writer.write(
        classroomId: key.classroomId,
        dateStr: key.day,
        academicYearId: key.academicYearId,
        covered: {for (final line in sent) line.student.id},
        lines: sent
            .map(ClassPresenceMapper.exception)
            .nonNulls
            .toList(growable: false),
      );
      if (written == AttendanceDayWrite.raced) {
        return const Left(
          ConflictFailure(
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

  /// Sur un appel rouvert, un élève que personne n'a touché depuis la
  /// réouverture part tel qu'il est **en base maintenant** — une correction
  /// reçue entre-temps n'est jamais écrasée par la photo de l'écran.
  Future<List<ClassPresenceLine>> _freshUntouched(
    ClassDayKey key,
    List<ClassPresenceLine> lines,
  ) async {
    final fresh = await _days.read(key);
    if (!fresh.reopened) return lines;
    final touched = (await _days.draftMarks(key)).keys.toSet();
    final current = {for (final line in fresh.lines) line.student.id: line};
    return [
      for (final line in lines)
        touched.contains(line.student.id)
            ? line
            : current[line.student.id] ?? line,
    ];
  }

  @override
  Future<Either<Failure, Unit>> reopenDay(ClassDayKey key) =>
      _guard('Local attendance reopen failed', () async {
        await drafts.reopen(
          classroomId: key.classroomId,
          dateStr: key.day,
          academicYearId: key.academicYearId,
          reopenedAt: now(),
        );
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> retryDay(ClassDayKey key) =>
      _guard('Local attendance retry failed', () async {
        await outbox.requeue(
          AttendanceDayWriter.outboxEntryId(
            key.classroomId,
            key.day,
            key.academicYearId,
          ),
        );
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
          drafts: drafts,
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
