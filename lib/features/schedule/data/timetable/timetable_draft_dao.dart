import 'dart:math' as math;

import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_dao.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Un geste de brouillon à envoyer (contrat `POST /sync/schedule/draft-cells`).
sealed class DraftGesture {
  final String draftId;
  final String classroomId;
  final int clock;

  const DraftGesture(this.draftId, this.classroomId, this.clock);

  String get key;
}

final class StartGesture extends DraftGesture {
  const StartGesture(super.draftId, super.classroomId, super.clock);

  @override
  String get key => 'START:$draftId';
}

final class AbandonGesture extends DraftGesture {
  const AbandonGesture(super.draftId, super.classroomId, super.clock);

  @override
  String get key => 'ABANDON:$draftId';
}

final class CellGesture extends DraftGesture {
  final ClassTimetableCell cell;

  CellGesture(this.cell)
    : super(cell.draftId!, cell.classroomId, cell.clientUpdatedAtMs ?? 0);

  @override
  String get key => 'CELL:$draftId:${cell.day.wire}:${cell.slotId}';
}

/// Les gestes du brouillon sur l'appareil (R10, R15) : poser, libérer,
/// échanger, commencer, abandonner. Tout geste est gardé ici avec une horloge
/// **monotone**, puis part par le lot ; chaque réconciliation est gardée par
/// l'horloge envoyée — un geste plus récent n'est jamais écrasé.
class TimetableDraftDao {
  final Database _db;

  const TimetableDraftDao(this._db);

  static const _headers = TimetableDao.headers;
  static const _cells = TimetableDao.cells;
  static final _pending = RecordSyncState.pending.dbValue;

  /// Commencer (I7) : l'en-tête porte le geste, et le brouillon part de la
  /// version publiée — le serveur la recopie aussi, ses cases redescendront
  /// sur les mêmes lignes (clé naturelle).
  static Future<void> start(
    DatabaseExecutor txn, {
    required String classroomId,
    required String academicYearId,
    required String draftId,
    required List<ClassTimetableCell> published,
    required int nowMs,
  }) async {
    final rows = await txn.query(
      _headers,
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
    );
    if (rows.isEmpty) {
      await txn.insert(_headers, {
        'id': 'local:$classroomId',
        'classroom_id': classroomId,
        'academic_year_id': academicYearId,
        'revision': 0,
        'synced_at': nowMs,
      });
    }
    await txn.update(
      _headers,
      {
        'pending_gesture': 'START',
        'pending_draft_id': draftId,
        'pending_clock': nowMs,
        'sync_error_code': null,
      },
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
    );
    for (final cell in published) {
      final copy = _asDraft(cell, draftId);
      await txn.insert(
        _cells,
        TimetableDao.cellRow(copy, nowMs)
          ..['sync_status'] = RecordSyncState.synced.dbValue,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Poser, changer ou libérer une case (I8, I9) ; un échange (I10) est deux
  /// cases à la même horloge. Rend l'horloge posée.
  static Future<int> saveCells(
    DatabaseExecutor txn,
    List<ClassTimetableCell> cells, {
    required int nowMs,
  }) async {
    var clock = nowMs;
    for (final cell in cells) {
      final rows = await txn.query(
        _cells,
        columns: ['client_updated_at', 'server_updated_at'],
        where: 'id = ?',
        whereArgs: [cell.id],
      );
      if (rows.isNotEmpty) {
        final last = math.max(
          rows.first['client_updated_at'] as int? ?? 0,
          rows.first['server_updated_at'] as int? ?? 0,
        );
        clock = math.max(clock, last + 1);
      }
    }
    for (final cell in cells) {
      await txn.insert(
        _cells,
        TimetableDao.cellRow(cell, nowMs)
          ..['client_updated_at'] = clock
          ..['sync_status'] = _pending
          ..['sync_error_code'] = null
          ..['superseded_at'] = null,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return clock;
  }

  /// Abandonner (I17) : le brouillon disparaît de l'appareil ; ses gestes non
  /// envoyés ne partent plus, seul l'abandon part.
  static Future<void> abandon(
    DatabaseExecutor txn, {
    required String classroomId,
    required String draftId,
    required int nowMs,
  }) async {
    await txn.delete(
      _cells,
      where: 'classroom_id = ? AND status = ? AND draft_id = ?',
      whereArgs: [classroomId, TimetableCellStatus.draft.wire, draftId],
    );
    await txn.update(
      _headers,
      {
        'pending_gesture': 'ABANDON',
        'pending_draft_id': draftId,
        'pending_clock': nowMs,
        'sync_error_code': null,
      },
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
    );
  }

  /// Le plafond d'un lot côté serveur, tous gestes confondus.
  static const int batchMax = 400;

  /// Les gestes à envoyer, classe par classe : commencer, puis les cases dans
  /// l'ordre des horloges, puis abandonner — [batchMax] au plus, commencer et
  /// abandonner compris ; le reste part au lot suivant.
  Future<List<DraftGesture>> pending({int limit = batchMax}) async {
    final starts = <String, DraftGesture>{};
    final abandons = <String, DraftGesture>{};
    for (final h in await _db.query(
      _headers,
      where: 'pending_gesture IS NOT NULL',
    )) {
      final classroom = h['classroom_id']! as String;
      final draft = h['pending_draft_id']! as String;
      final clock = (h['pending_clock'] as int?) ?? 0;
      if (h['pending_gesture'] == 'START') {
        starts[classroom] = StartGesture(draft, classroom, clock);
      } else {
        abandons[classroom] = AbandonGesture(draft, classroom, clock);
      }
    }
    final cells = await _db.query(
      _cells,
      where: 'sync_status = ? AND status = ?',
      whereArgs: [_pending, TimetableCellStatus.draft.wire],
      orderBy: 'classroom_id, client_updated_at, id',
      limit: math.max(0, limit - starts.length - abandons.length),
    );
    final byClass = <String, List<DraftGesture>>{};
    for (final r in cells) {
      final cell = TimetableDao.cellOf(r);
      byClass.putIfAbsent(cell.classroomId, () => []).add(CellGesture(cell));
    }
    final classrooms = {...starts.keys, ...byClass.keys, ...abandons.keys};
    return [
      for (final c in classrooms) ...[?starts[c], ...?byClass[c], ?abandons[c]],
    ];
  }

  Future<bool> hasPending(String classroomId) async {
    final h = await _db.query(
      _headers,
      where: 'classroom_id = ? AND pending_gesture IS NOT NULL',
      whereArgs: [classroomId],
      limit: 1,
    );
    if (h.isNotEmpty) return true;
    final c = await _db.query(
      _cells,
      where: 'classroom_id = ? AND sync_status = ?',
      whereArgs: [classroomId, _pending],
      limit: 1,
    );
    return c.isNotEmpty;
  }

  // ── Réconciliation (un résultat par geste) ──

  /// START accusé : le brouillon prend son id canonique (A9 : un id inconnu
  /// devient l'alias du brouillon ouvert) ; ses cases locales le suivent.
  Future<void> startApplied(StartGesture g, {String? canonicalDraftId}) async {
    final canonical = canonicalDraftId ?? g.draftId;
    await _db.transaction((txn) async {
      await txn.update(
        _headers,
        {
          'pending_gesture': null,
          'pending_draft_id': null,
          'pending_clock': null,
          'draft_id': canonical,
        },
        where: 'classroom_id = ? AND pending_gesture = ? AND pending_clock = ?',
        whereArgs: [g.classroomId, 'START', g.clock],
      );
      if (canonical == g.draftId) return;
      final rows = await txn.query(
        _cells,
        where: 'classroom_id = ? AND status = ? AND draft_id = ?',
        whereArgs: [g.classroomId, TimetableCellStatus.draft.wire, g.draftId],
      );
      for (final r in rows) {
        final moved = _asDraft(TimetableDao.cellOf(r), canonical);
        await txn.delete(_cells, where: 'id = ?', whereArgs: [r['id']]);
        await txn.insert(_cells, {
          ...r,
          'id': moved.id,
          'draft_id': canonical,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> abandonApplied(AbandonGesture g) => _db.update(
    _headers,
    {
      'pending_gesture': null,
      'pending_draft_id': null,
      'pending_clock': null,
      'draft_id': null,
    },
    where: 'classroom_id = ? AND pending_gesture = ? AND pending_clock = ?',
    whereArgs: [g.classroomId, 'ABANDON', g.clock],
  );

  Future<void> gestureRejected(DraftGesture g, String? code) => g is CellGesture
      ? _db.update(
          _cells,
          {
            'sync_status': RecordSyncState.failed.dbValue,
            'sync_error_code': code,
          },
          where: 'id = ? AND client_updated_at = ? AND sync_status = ?',
          whereArgs: [g.cell.id, g.clock, _pending],
        )
      : _db.update(
          _headers,
          {
            'pending_gesture': null,
            'pending_draft_id': null,
            'pending_clock': null,
            'sync_error_code': code,
          },
          where: 'classroom_id = ? AND pending_clock = ?',
          whereArgs: [g.classroomId, g.clock],
        );

  /// CELL APPLIED ou SUPERSEDED : l'état du serveur, s'il est rendu.
  Future<void> cellApplied(
    CellGesture g, {
    ClassTimetableCell? server,
    required bool superseded,
    required int nowMs,
  }) => _db.update(
    _cells,
    {
      if (server != null) ...TimetableDao.cellRow(server, nowMs)..remove('id'),
      'sync_status': RecordSyncState.synced.dbValue,
      'sync_error_code': null,
      'superseded_at': superseded ? nowMs : null,
    },
    where: 'id = ? AND client_updated_at = ? AND sync_status = ?',
    whereArgs: [g.cell.id, g.clock, _pending],
  );

  static ClassTimetableCell _asDraft(ClassTimetableCell c, String draftId) =>
      ClassTimetableCell(
        id: ClassTimetableCell.keyOf(
          classroomId: c.classroomId,
          status: TimetableCellStatus.draft,
          draftId: draftId,
          day: c.day,
          slotId: c.slotId,
        ),
        classroomId: c.classroomId,
        classroomLabel: c.classroomLabel,
        status: TimetableCellStatus.draft,
        draftId: draftId,
        day: c.day,
        slotId: c.slotId,
        range: c.range,
        coursId: c.coursId,
        teacherId: c.teacherId,
        subjectLabel: c.subjectLabel,
        teacherLabel: c.teacherLabel,
      );
}
