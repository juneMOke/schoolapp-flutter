import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les cycles et niveaux de l'année en cours, lus dans le référentiel
/// Inscription (`ref_academic_years`, `ref_school_level_groups`,
/// `ref_school_levels`), scopés par école.
class CalendarScopeOptionsDao {
  final DatabaseExecutor _db;

  const CalendarScopeOptionsDao(this._db);

  Future<CalendarScopeOptions> current(String schoolId) async {
    final years = await _db.query(
      'ref_academic_years',
      columns: ['id'],
      where: 'school_id = ? AND is_current = 1',
      whereArgs: [schoolId],
      limit: 1,
    );
    if (years.isEmpty) return const CalendarScopeOptions();
    final groups = await _db.query(
      'ref_school_level_groups',
      where: 'academic_year_id = ?',
      whereArgs: [years.first['id']],
      orderBy: 'display_order, name',
    );
    final codeById = {
      for (final g in groups) g['id']! as String: g['code']! as String,
    };
    final levels = codeById.isEmpty
        ? const <Map<String, Object?>>[]
        : await _db.query(
            'ref_school_levels',
            where:
                'level_group_id IN (${List.filled(codeById.length, '?').join(', ')})',
            whereArgs: codeById.keys.toList(),
            orderBy: 'display_order, name',
          );
    return CalendarScopeOptions(
      cycles: [
        for (final g in groups)
          CalendarCycleOption(
            code: g['code']! as String,
            name: g['name']! as String,
            rhythm: PeriodRhythm.fromWire(g['period_type'] as String?),
          ),
      ],
      levels: [
        for (final l in levels)
          CalendarLevelOption(
            cycleCode: codeById[l['level_group_id']]!,
            code: l['code']! as String,
            name: l['name']! as String,
          ),
      ],
    );
  }
}
