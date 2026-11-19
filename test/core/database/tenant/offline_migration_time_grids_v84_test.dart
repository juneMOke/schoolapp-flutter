import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/offline_database_opener.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v84 — les grilles par cycle et les minutes des séances : une table
/// neuve, trois colonnes, et le re-tirage des créneaux et des séances.
void main() {
  sqfliteFfiInit();
  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute(
      'CREATE TABLE ref_time_slots (id TEXT PRIMARY KEY, slot_order INTEGER NOT NULL, start_time TEXT NOT NULL, end_time TEXT NOT NULL, label TEXT, server_updated_at INTEGER, synced_at INTEGER NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE ref_recurring_sessions (id TEXT PRIMARY KEY, subject_label TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE sync_meta (resource TEXT PRIMARY KEY, cursor TEXT)',
    );
    for (final r in [
      'schedule_time_slots',
      'schedule_time_slots_bootstrap',
      'schedule_sessions@u1',
      'schedule_sessions_bootstrap@u1',
      'finance_payments',
    ]) {
      await db.insert('sync_meta', {'resource': r, 'cursor': 'x'});
    }
  });
  tearDown(() => db.close());

  Future<List<String>> columns(Database d, String table) async => [
    for (final r in await d.rawQuery('PRAGMA table_info($table)'))
      r['name']! as String,
  ];

  test(
    'colonnes ajoutées, curseurs de l’emploi du temps remis à zéro',
    () async {
      await migrateTenantDatabase(db, 83, newVersion: 84);
      expect(await columns(db, 'ref_time_slots'), contains('time_grid_id'));
      expect(
        await columns(db, 'ref_recurring_sessions'),
        containsAll(['start_minute', 'end_minute']),
      );
      expect(await db.query('ref_time_grids'), isEmpty);
      final left = [for (final r in await db.query('sync_meta')) r['resource']];
      expect(left, ['finance_payments']);
    },
  );

  test(
    'rejouable, et la table neuve a les colonnes d’une base neuve',
    () async {
      await migrateTenantDatabase(db, 83, newVersion: 84);
      await expectLater(
        migrateTenantDatabase(db, 83, newVersion: 84),
        completes,
      );
      final fresh = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(fresh.close);
      await createOfflineSchema(fresh, buildOfflineSchema());
      expect(
        await columns(db, 'ref_time_grids'),
        await columns(fresh, 'ref_time_grids'),
      );
    },
  );
}
