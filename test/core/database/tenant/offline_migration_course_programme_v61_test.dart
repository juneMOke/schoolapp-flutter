import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/schema/academics_offline_schema.dart';
import 'package:school_app_flutter/core/database/schema/course_programme_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v61 — le programme de cours, et les chapitres de `ref_chapitre`
/// recopiés en ébauches.
Future<Database> _openDb() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(singleInstance: false),
);

void main() {
  sqfliteFfiInit();

  late Database db;

  Future<List<String>> columnsOf(Database on, String table) async => [
    for (final row in await on.rawQuery('PRAGMA table_info($table)'))
      row['name'] as String,
  ];

  setUp(() async {
    db = await _openDb();
    await db.execute(refChapitreTable.createTableSql);
    // Le même chapitre vu par deux comptes du poste : une seule ébauche.
    for (final owner in ['u-1', 'u-2']) {
      await db.insert('ref_chapitre', {
        'id': 'ch-1',
        'owner_uid': owner,
        'cours_id': 'c-1',
        'titre': 'Nombres entiers',
        'ordre': 0,
      });
    }
  });
  tearDown(() => db.close());

  test(
    'les tables naissent et les chapitres deviennent des ébauches',
    () async {
      await migrateTenantDatabase(db, 60, newVersion: 61);

      final rows = await db.query('chapitre');
      expect(rows, hasLength(1));
      expect(rows.single['titre'], 'Nombres entiers');
      expect(rows.single['server_known'], 1);
      expect(rows.single['server_updated_at'], isNull);
      expect(rows.single['sync_status'], 'SYNCED');
      expect(await columnsOf(db, 'chapitre_note'), contains('chapitre_id'));
      expect(await columnsOf(db, 'chapitre_ressource'), contains('sha256'));
    },
  );

  test('sans référentiel de notes, le palier passe sans lever', () async {
    final bare = await _openDb();
    await migrateTenantDatabase(bare, 60, newVersion: 61);
    expect(await bare.query('chapitre'), isEmpty);
    await bare.close();
  });

  test('le palier se rejoue sans dupliquer', () async {
    await migrateTenantDatabase(db, 60, newVersion: 61);
    await migrateTenantDatabase(db, 60, newVersion: 61);
    expect(await db.query('chapitre'), hasLength(1));
  });

  test('base montée = base créée à neuf', () async {
    await migrateTenantDatabase(db, 60, newVersion: 61);
    final fresh = await _openDb();
    for (final table in courseProgrammeTables) {
      await fresh.execute(table.createTableSql);
    }
    for (final table in courseProgrammeTables) {
      expect(
        (await columnsOf(db, table.name))..sort(),
        (await columnsOf(fresh, table.name))..sort(),
      );
    }
    await fresh.close();
  });
}
