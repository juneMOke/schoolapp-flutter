import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v66 — le côté école du portail parent, en un seul palier pour tous
/// ses lots.
void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
  });
  tearDown(() => db.close());

  Future<List<String>> columnsOf(String table) async => [
    for (final row in await db.rawQuery('PRAGMA table_info($table)'))
      row['name'] as String,
  ];

  test(
    'les justifications naissent avec leurs deux jeux de colonnes',
    () async {
      await migrateTenantDatabase(db, 65, newVersion: 66);

      expect(
        await columnsOf('attendance_justifications'),
        containsAll([
          'id',
          'student_id',
          'attendance_date',
          'status',
          'file_sha256',
          'local_gesture_id',
          'local_decision',
          'accept_blocked_code',
          'decided_elsewhere',
          'sync_status',
        ]),
      );
      final indexes = await db.rawQuery(
        'PRAGMA index_list(attendance_justifications)',
      );
      expect(
        indexes.map((row) => row['name']),
        containsAll([
          'idx_attendance_justifications_status',
          'idx_attendance_justifications_day',
        ]),
      );
    },
  );

  test('une base déjà en v66 garde ses lignes au rejeu du palier', () async {
    await migrateTenantDatabase(db, 65, newVersion: 66);
    await db.insert('attendance_justifications', {
      'id': 'j',
      'student_id': 's',
      'classroom_id': 'c',
      'academic_year_id': 'y',
      'attendance_date': '2026-10-14',
      'reason': 'SICKNESS',
      'status': 'PENDING',
    });

    await migrateTenantDatabase(db, 65, newVersion: 66);

    expect(await db.query('attendance_justifications'), hasLength(1));
  });
}
