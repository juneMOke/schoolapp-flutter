import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/offline_database_opener.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v83 — le calendrier scolaire : quatre tables neuves, remplies par
/// les flux, et `ref_school_levels.catalog_level_code`, rempli par le
/// référentiel Inscription au tirage suivant.
void main() {
  sqfliteFfiInit();

  const tables = [
    'cal_frameworks',
    'cal_framework_items',
    'school_calendars',
    'school_calendar_events',
  ];

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    // Le niveau tel qu'il était en v82.
    await db.execute('''
      CREATE TABLE ref_school_levels (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0,
        level_group_id TEXT NOT NULL,
        split_into_classrooms INTEGER NOT NULL DEFAULT 0,
        synced_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.insert('ref_school_levels', {
      'id': 'l1',
      'name': '6e primaire',
      'code': 'P6',
      'level_group_id': 'g1',
    });
  });
  tearDown(() => db.close());

  Future<List<String>> columnsOf(Database d, String table) async => [
    for (final r in await d.rawQuery('PRAGMA table_info($table)'))
      r['name']! as String,
  ];

  test('les tables naissent vides, le niveau garde ses lignes', () async {
    await migrateTenantDatabase(db, 82, newVersion: 83);
    for (final table in tables) {
      expect(await db.query(table), isEmpty, reason: table);
    }
    expect(
      await columnsOf(db, 'ref_school_levels'),
      contains('catalog_level_code'),
    );
    final level = (await db.query('ref_school_levels')).single;
    expect(level['code'], 'P6');
    expect(level['catalog_level_code'], isNull);
  });

  test('rejouer le palier ne casse rien', () async {
    await migrateTenantDatabase(db, 82, newVersion: 83);
    await expectLater(migrateTenantDatabase(db, 82, newVersion: 83), completes);
  });

  test('une base montée et une base neuve ont les mêmes colonnes', () async {
    await migrateTenantDatabase(db, 82, newVersion: 83);
    final fresh = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(fresh.close);
    await createOfflineSchema(fresh, buildOfflineSchema());
    for (final table in tables) {
      expect(
        await columnsOf(db, table),
        await columnsOf(fresh, table),
        reason: table,
      );
    }
    // ALTER ajoute en fin de table : l'ordre diffère, l'ensemble non.
    expect(
      (await columnsOf(db, 'ref_school_levels')).toSet(),
      (await columnsOf(fresh, 'ref_school_levels')).toSet(),
    );
  });
}
