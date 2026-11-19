import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_wire.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les trois tables de l'emploi du temps par classe : le programme (bundle),
/// les en-têtes et les cases (flux keyset). Les cases portent aussi les gestes
/// de brouillon faits sur l'appareil : une ligne en attente n'est jamais
/// écrasée par un tirage — son envoi dira qui gagne.
class TimetableDao {
  final DatabaseExecutor _db;

  const TimetableDao(this._db);

  static const programmes = 'tt_programmes';
  static const headers = 'tt_class_timetables';
  static const cells = 'tt_cells';

  // ── Tirages ──

  Future<int> replaceProgrammes(
    List<TimetableCourse> courses,
    int nowMs,
  ) async {
    final batch = _db.batch()..delete(programmes);
    for (final c in courses) {
      batch.insert(programmes, {
        'cours_id': c.coursId,
        'classroom_id': c.classroomId,
        'branch_id': c.branchId,
        'branch_label': c.branchLabel,
        'domain_id': c.domainId,
        'domain_label': c.domainLabel,
        'domain_order': c.domainOrder,
        'teacher_id': c.teacherId,
        'teacher_label': c.teacherLabel,
        'weekly_hours': c.weeklyHours,
        'synced_at': nowMs,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return courses.length;
  }

  /// Un en-tête descendu remplace la ligne de sa classe (et la ligne locale
  /// `local:<classe>` d'une classe jamais publiée), **en gardant** un geste de
  /// brouillon encore en attente sur l'appareil.
  Future<int> applyHeaders(
    List<PulledTimetableRow<ClassTimetableHeader>> rows,
    int nowMs,
  ) async {
    for (final row in rows) {
      final h = row.value;
      final kept = await _db.query(
        headers,
        columns: [
          'pending_gesture',
          'pending_draft_id',
          'pending_clock',
          'sync_error_code',
        ],
        where: 'classroom_id = ? AND pending_gesture IS NOT NULL',
        whereArgs: [h.classroomId],
        limit: 1,
      );
      await _db.delete(
        headers,
        where: 'classroom_id = ? OR id = ?',
        whereArgs: [h.classroomId, h.id],
      );
      if (row.deleted) continue;
      await _db.insert(headers, {
        'id': h.id,
        'classroom_id': h.classroomId,
        'academic_year_id': h.academicYearId,
        'published_version': h.publishedVersion,
        'published_at': h.publishedAt?.toIso8601String(),
        'published_by_name': h.publishedBy?.name,
        'published_by_role': h.publishedBy?.role,
        'draft_id': h.draftId,
        'draft_updated_at': h.draftUpdatedAt?.toIso8601String(),
        'draft_updated_by_name': h.draftUpdatedBy?.name,
        'draft_updated_by_role': h.draftUpdatedBy?.role,
        'revision': h.revision,
        if (kept.isNotEmpty) ...kept.first,
        'server_updated_at': row.serverUpdatedAtMs,
        'synced_at': nowMs,
      });
    }
    return rows.length;
  }

  Future<int> applyCells(
    List<PulledTimetableRow<ClassTimetableCell>> rows,
    int nowMs,
  ) async {
    const pending = "sync_status = 'PENDING_SYNC'";
    final batch = _db.batch();
    for (final row in rows) {
      final c = row.value;
      if (row.deleted) {
        batch.delete(
          cells,
          where: 'id = ? AND NOT $pending',
          whereArgs: [c.id],
        );
        continue;
      }
      final values = cellRow(c, nowMs)
        ..['server_updated_at'] = row.serverUpdatedAtMs
        ..['sync_status'] = RecordSyncState.synced.dbValue;
      batch.rawInsert(
        'INSERT INTO $cells (${values.keys.join(', ')}) '
        'VALUES (${List.filled(values.length, '?').join(', ')}) '
        'ON CONFLICT(id) DO UPDATE SET '
        '${[for (final k in values.keys)
          if (k != 'id') '$k = excluded.$k'].join(', ')} '
        'WHERE NOT $cells.$pending',
        values.values.toList(),
      );
    }
    await batch.commit(noResult: true);
    return rows.length;
  }

  static Map<String, Object?> cellRow(ClassTimetableCell c, int nowMs) => {
    'id': c.id,
    'classroom_id': c.classroomId,
    'classroom_label': c.classroomLabel,
    'status': c.status.wire,
    'draft_id': c.draftId,
    'day': c.day.wire,
    'slot_id': c.slotId,
    'start_minute': c.range.startMinute,
    'end_minute': c.range.endMinute,
    'cours_id': c.coursId,
    'teacher_id': c.teacherId,
    'subject_label': c.subjectLabel,
    'teacher_label': c.teacherLabel,
    'client_updated_at': c.clientUpdatedAtMs,
    'synced_at': nowMs,
  };

  // ── Lectures ──

  Future<List<TimetableCourse>> programmeOf(String classroomId) async => [
    for (final r in await _db.query(
      programmes,
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
      orderBy: 'domain_order, branch_label',
    ))
      _courseOf(r),
  ];

  Future<ClassTimetableHeader?> headerOf(String classroomId) async {
    final rows = await _db.query(
      headers,
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
      limit: 1,
    );
    return rows.isEmpty ? null : _headerOf(rows.first);
  }

  /// Les cases d'une classe : publiées, ou celles d'un brouillon.
  Future<List<ClassTimetableCell>> cellsOf(
    String classroomId, {
    required TimetableCellStatus status,
    String? draftId,
  }) async => [
    for (final r in await _db.query(
      cells,
      where: status == TimetableCellStatus.draft
          ? 'classroom_id = ? AND status = ? AND draft_id = ?'
          : 'classroom_id = ? AND status = ?',
      whereArgs: [classroomId, status.wire, ?draftId],
    ))
      cellOf(r),
  ];

  /// Les séances qui occupent des enseignants ailleurs que dans [classroomId],
  /// publiées et en brouillon (R4, Q4) — pour les conflits sur l'appareil.
  Future<List<TeacherBooking>> bookingsOutside(String classroomId) async => [
    for (final r in await _db.query(
      cells,
      where:
          'classroom_id <> ? AND teacher_id IS NOT NULL AND cours_id IS NOT NULL',
      whereArgs: [classroomId],
    ))
      TeacherBooking(
        teacherId: r['teacher_id']! as String,
        day: WeekdayX.fromWire(r['day'] as String?),
        range: MinuteRange(r['start_minute']! as int, r['end_minute']! as int),
        classroomId: r['classroom_id']! as String,
        classroomLabel: r['classroom_label']! as String,
      ),
  ];

  static TimetableCourse _courseOf(Map<String, Object?> r) => TimetableCourse(
    coursId: r['cours_id']! as String,
    classroomId: r['classroom_id']! as String,
    branchId: r['branch_id']! as String,
    branchLabel: r['branch_label']! as String,
    domainId: r['domain_id'] as String?,
    domainLabel: r['domain_label'] as String?,
    domainOrder: r['domain_order'] as int?,
    teacherId: r['teacher_id'] as String?,
    teacherLabel: r['teacher_label'] as String?,
    weeklyHours: r['weekly_hours'] as int?,
  );

  /// Le brouillon que l'écran montre tient compte d'un geste en attente :
  /// un « commencer » ouvre son brouillon, un « abandonner » le ferme.
  static ClassTimetableHeader _headerOf(Map<String, Object?> r) {
    final pending = r['pending_gesture'] as String?;
    final draftId = switch (pending) {
      'START' => r['pending_draft_id'] as String?,
      'ABANDON' => null,
      _ => r['draft_id'] as String?,
    };
    return ClassTimetableHeader(
      id: r['id']! as String,
      classroomId: r['classroom_id']! as String,
      academicYearId: r['academic_year_id']! as String,
      publishedVersion: r['published_version'] as int?,
      publishedAt: DateTime.tryParse((r['published_at'] as String?) ?? ''),
      publishedBy: _actor(r['published_by_name'], r['published_by_role']),
      draftId: draftId,
      draftUpdatedAt: DateTime.tryParse(
        (r['draft_updated_at'] as String?) ?? '',
      ),
      draftUpdatedBy: _actor(
        r['draft_updated_by_name'],
        r['draft_updated_by_role'],
      ),
      revision: (r['revision'] as int?) ?? 0,
      pendingGesture: pending,
      errorCode: r['sync_error_code'] as String?,
    );
  }

  static TimetableActor? _actor(Object? name, Object? role) =>
      name == null && role == null
      ? null
      : TimetableActor(name: name as String?, role: role as String?);

  static ClassTimetableCell cellOf(Map<String, Object?> r) =>
      ClassTimetableCell(
        id: r['id']! as String,
        classroomId: r['classroom_id']! as String,
        classroomLabel: r['classroom_label']! as String,
        status: TimetableCellStatus.fromWire(r['status'] as String?),
        draftId: r['draft_id'] as String?,
        day: WeekdayX.fromWire(r['day'] as String?),
        slotId: r['slot_id']! as String,
        range: MinuteRange(r['start_minute']! as int, r['end_minute']! as int),
        coursId: r['cours_id'] as String?,
        teacherId: r['teacher_id'] as String?,
        subjectLabel: r['subject_label'] as String?,
        teacherLabel: r['teacher_label'] as String?,
        clientUpdatedAtMs: r['client_updated_at'] as int?,
        syncState: RecordSyncState.fromDb(r['sync_status'] as String?),
        errorCode: r['sync_error_code'] as String?,
        superseded: r['superseded_at'] != null,
      );
}
