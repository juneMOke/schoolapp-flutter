import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_draft_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_draft_outbox_handler.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les refus de l'emploi du temps (422, `detailCode`).
class TimetableRefusalFailure extends Failure {
  final String code;
  final List<Map<String, dynamic>> conflicts;

  const TimetableRefusalFailure(this.code, {this.conflicts = const []})
    : super('Refus de l\'emploi du temps');

  @override
  List<Object?> get props => [code, conflicts];
}

/// Une case à poser : un cours ou rien (libérer).
class CellChange {
  final Weekday day;
  final TimeSlot slot;
  final TimetableCourse? course;

  const CellChange(this.day, this.slot, this.course);
}

/// Les gestes du brouillon (R10, R15) : chacun est gardé sur l'appareil puis
/// part par le lot (A18), web compris ; seule la publication est en ligne.
class TimetableEditor {
  final Database _db;
  final Dio _dio;
  final Map<String, dynamic> _requiredAuth;
  final IdGenerator _ids;
  final String? Function() _schoolId;
  final SyncEngine? _engine;
  final DateTime Function() _now;

  TimetableEditor({
    required Database db,
    required Dio dio,
    required Map<String, dynamic> requiredAuth,
    required IdGenerator ids,
    required String? Function() schoolId,
    SyncEngine? engine,
    DateTime Function()? now,
  }) : _db = db,
       _dio = dio,
       _requiredAuth = requiredAuth,
       _ids = ids,
       _schoolId = schoolId,
       _engine = engine,
       _now = now ?? DateTime.now;

  Future<Either<Failure, Unit>> start(ClassTimetableView view) => _write(
    (txn, nowMs) => TimetableDraftDao.start(
      txn,
      classroomId: view.classroom.classroomId,
      academicYearId: view.header?.academicYearId ?? '',
      draftId: _ids.newId(),
      published: view.published,
      nowMs: nowMs,
    ),
  );

  /// Pose, change, libère ; un échange est deux changements à la même horloge.
  Future<Either<Failure, Unit>> setCells(
    ClassTimetableView view,
    List<CellChange> changes,
  ) {
    final draftId = view.header?.draftId;
    if (draftId == null) return Future.value(const Left(StorageFailure()));
    return _write(
      (txn, nowMs) => TimetableDraftDao.saveCells(txn, [
        for (final c in changes) _cell(view, draftId, c),
      ], nowMs: nowMs),
    );
  }

  Future<Either<Failure, Unit>> abandon(ClassTimetableView view) {
    final draftId = view.header?.draftId;
    if (draftId == null) return Future.value(const Left(StorageFailure()));
    return _write(
      (txn, nowMs) => TimetableDraftDao.abandon(
        txn,
        classroomId: view.classroom.classroomId,
        draftId: draftId,
        nowMs: nowMs,
      ),
    );
  }

  /// Publier (R9) : en ligne, avec la révision lue ; un double appui ne publie
  /// qu'une fois (le serveur répond 200 sans rien refaire).
  Future<Either<Failure, Unit>> publish(ClassTimetableView view) async {
    final draftId = view.header?.draftId;
    if (draftId == null) return const Left(StorageFailure());
    try {
      await _dio.post<Map<String, dynamic>>(
        AppConstants.timetablePublishEndpoint(
          view.classroom.classroomId,
          draftId,
        ),
        data: {'revision': view.header!.revision},
        options: Options(extra: _requiredAuth),
      );
      return const Right(unit);
    } on DioException catch (e) {
      final code = ApiErrorParser.detailCodeOf(e.response);
      if (code != null && code.startsWith('TIMETABLE_')) {
        final details = ApiErrorParser.detailsOf(e.response) ?? const {};
        return Left(
          TimetableRefusalFailure(
            code,
            conflicts: [
              for (final c in (details['conflicts'] as List?) ?? const [])
                if (c is Map<String, dynamic>) c,
            ],
          ),
        );
      }
      return guardOnline<Unit>(() => Future.error(e));
    }
  }

  ClassTimetableCell _cell(
    ClassTimetableView view,
    String draftId,
    CellChange c,
  ) {
    final range =
        MinuteRange.fromClocks(c.slot.startTime, c.slot.endTime) ??
        const MinuteRange(0, 0);
    final classroomId = view.classroom.classroomId;
    return ClassTimetableCell(
      id: ClassTimetableCell.keyOf(
        classroomId: classroomId,
        status: TimetableCellStatus.draft,
        draftId: draftId,
        day: c.day,
        slotId: c.slot.id,
      ),
      classroomId: classroomId,
      classroomLabel: view.classroom.name,
      status: TimetableCellStatus.draft,
      draftId: draftId,
      day: c.day,
      slotId: c.slot.id,
      range: range,
      coursId: c.course?.coursId,
      teacherId: c.course?.teacherId,
      subjectLabel: c.course?.branchLabel,
      teacherLabel: c.course?.teacherLabel,
    );
  }

  /// Le geste et son envoi dans **une** transaction.
  Future<Either<Failure, Unit>> _write(
    Future<void> Function(Transaction txn, int nowMs) gesture,
  ) async {
    final schoolId = _schoolId();
    if (schoolId == null || schoolId.isEmpty) {
      return const Left(StorageFailure('Aucune école courante'));
    }
    try {
      final nowMs = _now().millisecondsSinceEpoch;
      await _db.transaction((txn) async {
        await gesture(txn, nowMs);
        await OutboxDao(txn).enqueue(
          timetableDraftOutboxEntry(schoolId: schoolId, createdAt: nowMs),
        );
      });
      final engine = _engine;
      if (engine != null) unawaited(engine.flush());
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
