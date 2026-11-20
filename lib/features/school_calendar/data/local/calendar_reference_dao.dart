import 'package:school_app_flutter/core/database/schema/school_calendar_schema.dart';
import 'package:school_app_flutter/features/school_calendar/data/wire/calendar_wire.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_actor.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les cadres nationaux et les en-têtes de calendrier descendus : ce que
/// l'appareil ne fait que lire.
class CalendarReferenceDao {
  final DatabaseExecutor _db;

  const CalendarReferenceDao(this._db);

  static final String _frameworks = calFrameworksTable.name;
  static final String _items = calFrameworkItemsTable.name;
  static final String _calendars = schoolCalendarsTable.name;

  /// Une page de `calendar.framework` : chaque cadre remplace la ligne et
  /// **tous** les éléments de son année (une version retire sans pierre
  /// tombale).
  Future<int> applyFrameworks(
    List<Pulled<NationalFramework>> rows, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (rows.isEmpty || schoolId.isEmpty) return 0;
    final batch = _db.batch();
    for (final row in rows) {
      final f = row.value;
      batch.delete(
        _items,
        where:
            'framework_id IN (SELECT id FROM $_frameworks '
            'WHERE school_id = ? AND year_label = ?) OR framework_id = ?',
        whereArgs: [schoolId, f.yearLabel, f.id],
      );
      batch.delete(
        _frameworks,
        where: 'school_id = ? AND year_label = ? AND id <> ?',
        whereArgs: [schoolId, f.yearLabel, f.id],
      );
      batch.insert(_frameworks, {
        'id': f.id,
        'school_id': schoolId,
        'year_label': f.yearLabel,
        'version': f.version,
        'start_date': CalendarDays.format(f.startDate),
        'end_date': CalendarDays.format(f.endDate),
        'document_file_name': f.document?.fileName,
        'document_size_bytes': f.document?.sizeBytes,
        'document_uploaded_at': f.document?.uploadedAt
            ?.toUtc()
            .toIso8601String(),
        'server_updated_at': row.serverUpdatedAtMs,
        'synced_at': nowMs,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (final item in f.items) {
        batch.insert(_items, {
          'id': item.id,
          'framework_id': f.id,
          'nature': item.nature.wire,
          'title': item.title,
          'start_date': CalendarDays.format(item.startDate),
          'end_date': CalendarDays.format(item.endDate),
          'scope': item.scope.wire,
          'rhythm': item.rhythm?.wire,
          'period_order': item.periodOrder,
          'sub_period_order': item.subPeriodOrder,
          'replaceable': item.replaceable ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
    return rows.length;
  }

  Future<int> applyCalendars(
    List<Pulled<SchoolCalendar>> rows, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (rows.isEmpty || schoolId.isEmpty) return 0;
    final batch = _db.batch();
    for (final row in rows) {
      batch.insert(
        _calendars,
        calendarRow(row.value, schoolId: schoolId, nowMs: nowMs)
          ..['server_updated_at'] = row.serverUpdatedAtMs,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    return rows.length;
  }

  /// La ligne d'un en-tête — aussi pour recopier sans attendre la réponse
  /// d'un geste en ligne (créer, dupliquer, publier).
  static Map<String, Object?> calendarRow(
    SchoolCalendar c, {
    required String schoolId,
    required int nowMs,
  }) => {
    'id': c.id,
    'school_id': schoolId,
    'year_label': c.yearLabel,
    'status': c.status.wire,
    'start_date': CalendarDays.format(c.startDate),
    'end_date': CalendarDays.format(c.endDate),
    'framework': c.framework.wire,
    'framework_version': c.frameworkVersion,
    'published_at': c.publishedAt?.toUtc().toIso8601String(),
    'published_by_name': c.publishedBy?.name,
    'published_by_role': c.publishedBy?.role,
    'updated_at': c.updatedAt?.toUtc().toIso8601String(),
    'revision': c.revision,
    'synced_at': nowMs,
  };

  Future<List<SchoolCalendar>> calendars(String schoolId) async {
    final rows = await _db.query(
      _calendars,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy: 'year_label DESC',
    );
    return [for (final r in rows) _calendarOf(r)];
  }

  Future<List<NationalFramework>> frameworks(String schoolId) async {
    final heads = await _db.query(
      _frameworks,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    final result = <NationalFramework>[];
    for (final h in heads) {
      final items = await _db.query(
        _items,
        where: 'framework_id = ?',
        whereArgs: [h['id']],
        orderBy: 'start_date, id',
      );
      result.add(
        NationalFramework(
          id: h['id']! as String,
          yearLabel: h['year_label']! as String,
          version: h['version']! as int,
          startDate: CalendarDays.tryParse(h['start_date'] as String?)!,
          endDate: CalendarDays.tryParse(h['end_date'] as String?)!,
          items: [for (final i in items) _itemOf(i)],
          document: switch (h['document_file_name']) {
            final String name => FrameworkDocument(
              fileName: name,
              sizeBytes: h['document_size_bytes'] as int?,
              uploadedAt: DateTime.tryParse(
                (h['document_uploaded_at'] as String?) ?? '',
              ),
            ),
            _ => null,
          },
        ),
      );
    }
    return result;
  }

  static SchoolCalendar _calendarOf(Map<String, Object?> r) => SchoolCalendar(
    id: r['id']! as String,
    yearLabel: r['year_label']! as String,
    status: CalendarStatus.fromWire(r['status'] as String?),
    startDate: CalendarDays.tryParse(r['start_date'] as String?)!,
    endDate: CalendarDays.tryParse(r['end_date'] as String?)!,
    framework: FrameworkState.fromWire(r['framework'] as String?),
    frameworkVersion: r['framework_version'] as int?,
    publishedAt: DateTime.tryParse((r['published_at'] as String?) ?? ''),
    publishedBy:
        r['published_by_name'] == null && r['published_by_role'] == null
        ? null
        : CalendarActor(
            name: r['published_by_name'] as String?,
            role: r['published_by_role'] as String?,
          ),
    updatedAt: DateTime.tryParse((r['updated_at'] as String?) ?? ''),
    revision: (r['revision'] as int?) ?? 0,
  );

  static CalendarElement _itemOf(Map<String, Object?> r) => CalendarElement(
    id: r['id']! as String,
    source: CalendarSource.national,
    nature: CalendarNature.fromWire(r['nature'] as String?),
    title: r['title']! as String,
    startDate: CalendarDays.tryParse(r['start_date'] as String?)!,
    endDate: CalendarDays.tryParse(r['end_date'] as String?)!,
    scope: CalendarScope.parse(r['scope'] as String?),
    rhythm: PeriodRhythm.fromWire(r['rhythm'] as String?),
    periodOrder: r['period_order'] as int?,
    subPeriodOrder: r['sub_period_order'] as int?,
    replaceable: r['replaceable'] == 1,
  );
}
