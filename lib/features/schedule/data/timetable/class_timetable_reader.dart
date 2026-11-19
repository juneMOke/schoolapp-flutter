import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/schedule/data/sync/time_grids_pull_handler.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_draft_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_pull_handlers.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_grid.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// La lecture locale de l'emploi du temps d'une classe : ses options de
/// choix, sa grille (par le code de son cycle, sinon la grille par défaut),
/// sa version publiée, son brouillon et son programme.
class ClassTimetableReader {
  final Database _db;
  final TimetableDao _dao;
  final TimeGridDao _grids;
  final SyncMetaDao _meta;
  final String? Function() _schoolId;

  ClassTimetableReader(
    this._db,
    this._meta, {
    required String? Function() schoolId,
  }) : _dao = TimetableDao(_db),
       _grids = TimeGridDao(_db),
       _schoolId = schoolId;

  /// Les classes de l'année en cours, avec leur cycle et leur niveau.
  Future<List<TimetableClassOption>> classOptions() async {
    final rows = await _db.rawQuery('''
      SELECT c.id, c.name, c.room, g.code AS cycle_code, g.name AS cycle_name,
             l.code AS level_code, l.name AS level_name
      FROM ref_classrooms c
      JOIN ref_academic_years y ON y.id = c.academic_year_id AND y.is_current = 1
      JOIN ref_school_level_groups g ON g.id = c.school_level_group_id
      JOIN ref_school_levels l ON l.id = c.school_level_id
      ORDER BY g.display_order, l.display_order, c.name
    ''');
    return [
      for (final r in rows)
        TimetableClassOption(
          classroomId: r['id']! as String,
          name: r['name']! as String,
          room: r['room'] as String?,
          cycleCode: r['cycle_code']! as String,
          cycleName: r['cycle_name']! as String,
          levelCode: r['level_code']! as String,
          levelName: r['level_name']! as String,
        ),
    ];
  }

  Future<ClassTimetableView> load(TimetableClassOption classroom) async {
    final grids = await _grids.all();
    final grid = TimeGrid.forCycle(classroom.cycleCode, grids.values);
    final slotRows = await _db.query(
      'ref_time_slots',
      where: grid == null ? null : 'time_grid_id = ? OR time_grid_id IS NULL',
      whereArgs: grid == null ? null : [grid.id],
    );
    final slots = [
      for (final r in slotRows)
        TimeSlot(
          id: r['id']! as String,
          order: r['slot_order']! as int,
          startTime: r['start_time']! as String,
          endTime: r['end_time']! as String,
          label: r['label'] as String?,
        ),
    ]..sort(TimeSlot.compareByTime);
    final header = await _dao.headerOf(classroom.classroomId);
    final draftId = header?.draftId;
    final schoolId = _schoolId() ?? '';
    return ClassTimetableView(
      classroom: classroom,
      grid: grid,
      slots: slots,
      header: header,
      published: await _dao.cellsOf(
        classroom.classroomId,
        status: TimetableCellStatus.published,
      ),
      draft: draftId == null
          ? const []
          : await _dao.cellsOf(
              classroom.classroomId,
              status: TimetableCellStatus.draft,
              draftId: draftId,
            ),
      programme: await _dao.programmeOf(classroom.classroomId),
      othersKnown:
          await _meta.getCursor('$kScheduleTimetableCellsResource@$schoolId') !=
          null,
      bookings: await _dao.bookingsOutside(classroom.classroomId),
      hasPending: await TimetableDraftDao(
        _db,
      ).hasPending(classroom.classroomId),
    );
  }
}
