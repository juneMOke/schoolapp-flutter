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
    final clock = _nextClock(rows, nowMs);
    // Un abandon encore en attente part AVANT ce nouveau brouillon : sinon le
    // serveur ferait du nouveau l'alias de l'ancien, resté ouvert (A9).
    final restart =
        rows.isNotEmpty && rows.first['pending_gesture'] == _abandonGesture;
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
        'pending_gesture': restart ? _restartGesture : _startGesture,
        'pending_draft_id': draftId,
        'pending_abandon_draft_id': restart
            ? rows.first['pending_draft_id']
            : null,
        'pending_clock': clock,
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
    final rows = await txn.query(
      _headers,
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
    );
    final pending = rows.firstOrNull?['pending_gesture'];
    final pendingDraft = rows.firstOrNull?['pending_draft_id'];
    // Un brouillon jamais envoyé s'abandonne sur l'appareil seul : rien à
    // dire au serveur (ni START ni ABANDON). Un RESTART redevient l'abandon
    // de l'ancien brouillon, qui seul reste à envoyer.
    final Map<String, Object?> values = switch (pending) {
      _startGesture when pendingDraft == draftId => {
        'pending_gesture': null,
        'pending_draft_id': null,
        'pending_clock': null,
      },
      _restartGesture when pendingDraft == draftId => {
        'pending_gesture': _abandonGesture,
        'pending_draft_id': rows.first['pending_abandon_draft_id'],
        'pending_abandon_draft_id': null,
      },
      _ => {
        'pending_gesture': _abandonGesture,
        'pending_draft_id': draftId,
        'pending_abandon_draft_id': null,
        'pending_clock': _nextClock(rows, nowMs),
      },
    };
    await txn.update(
      _headers,
      {...values, 'sync_error_code': null},
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
    );
  }

  static const _startGesture = 'START';
  static const _abandonGesture = 'ABANDON';

  /// Un abandon (de `draft_id`) suivi d'un commencer (`pending_draft_id`).
  static const _restartGesture = 'RESTART';

  /// L'horloge d'un geste d'en-tête, monotone : jamais en deçà du geste
  /// précédent, même horloge de tablette reculée.
  static int _nextClock(List<Map<String, Object?>> rows, int nowMs) {
    final last = rows.firstOrNull?['pending_clock'] as int?;
    return last == null ? nowMs : math.max(nowMs, last + 1);
  }

  /// Le plafond d'un lot côté serveur, tous gestes confondus.
  static const int batchMax = 400;

  /// Les gestes à envoyer, classe par classe : commencer, puis les cases dans
  /// l'ordre des horloges, puis abandonner — [batchMax] au plus, commencer et
  /// abandonner compris ; le reste part au lot suivant.
  Future<List<DraftGesture>> pending({int limit = batchMax}) async {
    final restarts = <String, DraftGesture>{};
    final starts = <String, DraftGesture>{};
    final abandons = <String, DraftGesture>{};
    for (final h in await _db.query(
      _headers,
      where: 'pending_gesture IS NOT NULL',
    )) {
      final classroom = h['classroom_id']! as String;
      final draft = h['pending_draft_id']! as String;
      final clock = (h['pending_clock'] as int?) ?? 0;
      switch (h['pending_gesture']) {
        case _startGesture:
          starts[classroom] = StartGesture(draft, classroom, clock);
        case _restartGesture:
          final old = h['pending_abandon_draft_id']! as String;
          restarts[classroom] = AbandonGesture(old, classroom, clock);
          starts[classroom] = StartGesture(draft, classroom, clock);
        default:
          abandons[classroom] = AbandonGesture(draft, classroom, clock);
      }
    }
    final cells = await _db.query(
      _cells,
      where: 'sync_status = ? AND status = ?',
      whereArgs: [_pending, TimetableCellStatus.draft.wire],
      orderBy: 'classroom_id, client_updated_at, id',
      limit: math.max(
        0,
        limit - restarts.length - starts.length - abandons.length,
      ),
    );
    final byClass = <String, List<DraftGesture>>{};
    for (final r in cells) {
      final cell = TimetableDao.cellOf(r);
      byClass.putIfAbsent(cell.classroomId, () => []).add(CellGesture(cell));
    }
    final classrooms = {...starts.keys, ...byClass.keys, ...abandons.keys};
    return [
      for (final c in classrooms) ...[
        ?restarts[c],
        ?starts[c],
        ...?byClass[c],
        ?abandons[c],
      ],
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
          'pending_abandon_draft_id': null,
          'pending_clock': null,
          'draft_id': canonical,
        },
        where: 'classroom_id = ? AND pending_gesture = ? AND pending_clock = ?',
        whereArgs: [g.classroomId, _startGesture, g.clock],
      );
      if (canonical == g.draftId) return;
      // Alias (A9) : seuls les gestes de l'appareil suivent le brouillon
      // canonique ; les copies de la version publiée faites au START (jamais
      // écrites : horloge nulle) se retirent — le brouillon ouvert a ses
      // propres cases, qui descendent.
      await txn.delete(
        _cells,
        where:
            'classroom_id = ? AND status = ? AND draft_id = ? '
            'AND sync_status = ? AND client_updated_at IS NULL',
        whereArgs: [
          g.classroomId,
          TimetableCellStatus.draft.wire,
          g.draftId,
          RecordSyncState.synced.dbValue,
        ],
      );
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

  Future<void> abandonApplied(AbandonGesture g) => _db.transaction((txn) async {
    await txn.update(
      _headers,
      {
        'pending_gesture': null,
        'pending_draft_id': null,
        'pending_clock': null,
        'draft_id': null,
      },
      where: 'classroom_id = ? AND pending_gesture = ? AND pending_clock = ?',
      whereArgs: [g.classroomId, _abandonGesture, g.clock],
    );
    await _restartToStart(txn, g);
  });

  /// L'abandon d'un RESTART est réglé (accusé, ou refusé : l'ancien
  /// brouillon est déjà fini) — reste le commencer.
  static Future<void> _restartToStart(DatabaseExecutor txn, AbandonGesture g) =>
      txn.update(
        _headers,
        {'pending_gesture': _startGesture, 'pending_abandon_draft_id': null},
        where:
            'classroom_id = ? AND pending_gesture = ? AND pending_clock = ? '
            'AND pending_abandon_draft_id = ?',
        whereArgs: [g.classroomId, _restartGesture, g.clock, g.draftId],
      );

  Future<void> gestureRejected(DraftGesture g, String? code) async {
    if (g is AbandonGesture) {
      final moved = await _db.transaction((txn) async {
        final rows = await txn.query(
          _headers,
          columns: ['pending_gesture'],
          where: 'classroom_id = ? AND pending_clock = ?',
          whereArgs: [g.classroomId, g.clock],
        );
        if (rows.firstOrNull?['pending_gesture'] != _restartGesture) {
          return false;
        }
        await _restartToStart(txn, g);
        return true;
      });
      if (moved) return;
    }
    await _rejected(g, code);
  }

  Future<void> _rejected(DraftGesture g, String? code) => g is CellGesture
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
          where:
              'classroom_id = ? AND pending_clock = ? AND pending_gesture = ?',
          whereArgs: [
            g.classroomId,
            g.clock,
            g is StartGesture ? _startGesture : _abandonGesture,
          ],
        );

  /// CELL APPLIED ou SUPERSEDED : l'état du serveur, s'il est rendu.
  Future<void> cellApplied(
    CellGesture g, {
    ClassTimetableCell? server,
    int? serverUpdatedAtMs,
    required bool superseded,
    required int nowMs,
  }) => _db.update(
    _cells,
    {
      // La case du serveur porte le brouillon canonique (A9) ; la ligne garde
      // sa clé et son brouillon, que le START accusé renomme ensuite.
      if (server != null)
        ...TimetableDao.cellRow(server, nowMs)
          ..remove('id')
          ..remove('draft_id')
          ..remove('status')
          // L'horloge à battre au prochain geste : la plus haute des deux
          // (une copie du START gagnante n'en a pas, A8).
          ..['client_updated_at'] = math.max(
            g.clock,
            server.clientUpdatedAtMs ?? 0,
          ),
      'server_updated_at': ?serverUpdatedAtMs,
      'sync_status': RecordSyncState.synced.dbValue,
      'sync_error_code': null,
      'superseded_at': superseded ? nowMs : null,
    },
    where: 'id = ? AND client_updated_at = ? AND sync_status = ?',
    whereArgs: [g.cell.id, g.clock, _pending],
  );

  /// La révision rendue par un geste accusé ; jamais à reculons (un résultat
  /// plus ancien qu'un tirage ne la fait pas redescendre).
  Future<void> noteRevision(String classroomId, int revision) => _db.update(
    _headers,
    {'revision': revision},
    where: 'classroom_id = ? AND revision < ?',
    whereArgs: [classroomId, revision],
  );

  // ── Plusieurs appareils (R18, Q13 élargie) ──

  /// Les gestes refusés parce que leur brouillon a été publié ou abandonné
  /// entre-temps (TIMETABLE_DRAFT_ENDED) : gardés, jamais rattachés d'office.
  Future<List<ClassTimetableCell>> endedCells(String classroomId) async => [
    for (final r in await _db.query(
      _cells,
      where: 'classroom_id = ? AND sync_status = ? AND sync_error_code = ?',
      whereArgs: [
        classroomId,
        RecordSyncState.failed.dbValue,
        'TIMETABLE_DRAFT_ENDED',
      ],
    ))
      TimetableDao.cellOf(r),
  ];

  Future<void> discard(List<ClassTimetableCell> cells) async {
    for (final c in cells) {
      await _db.delete(_cells, where: 'id = ?', whereArgs: [c.id]);
    }
  }

  /// Les cases qu'un autre appareil a écrasées (SUPERSEDED), rendues une fois.
  Future<int> takeSuperseded(String classroomId) async => _db.update(
    _cells,
    {'superseded_at': null},
    where: 'classroom_id = ? AND superseded_at IS NOT NULL',
    whereArgs: [classroomId],
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
