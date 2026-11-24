import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/offline_database_opener.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v88 — les intitulés des colonnes de notes : `ref_grille` naît vide,
/// `ref_sous_periode` gagne `rang`, et le curseur du bundle repart de zéro
/// pour que le prochain tirage ne réponde pas 304 sur des grilles vides.
void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    // Les tables telles qu'elles étaient en v87.
    await db.execute('''
      CREATE TABLE ref_sous_periode (
        id TEXT NOT NULL,
        owner_uid TEXT NOT NULL DEFAULT '',
        periode_scolaire_id TEXT NOT NULL,
        ordre INTEGER NOT NULL DEFAULT 0,
        statut TEXT NOT NULL,
        start_date TEXT,
        end_date TEXT,
        PRIMARY KEY (id, owner_uid)
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_meta (
        resource TEXT PRIMARY KEY,
        cursor TEXT,
        synced_at INTEGER
      )
    ''');
    await db.insert('ref_sous_periode', {
      'id': 'sp1',
      'owner_uid': 'u1',
      'periode_scolaire_id': 'p1',
      'ordre': 1,
      'statut': 'OUVERTE',
    });
    for (final resource in [
      'academics_grades_referential',
      'academics_grades_referential@u1',
      'academics_cours@u1',
      'academics_grades_referential_x',
    ]) {
      await db.insert('sync_meta', {'resource': resource, 'cursor': 'etag'});
    }
  });
  tearDown(() => db.close());

  Future<List<String>> columnsOf(Database d, String table) async => [
    for (final r in await d.rawQuery('PRAGMA table_info($table)'))
      r['name']! as String,
  ];

  test('grilles vides, rang ajouté, sous-périodes gardées', () async {
    await migrateTenantDatabase(db, 87, newVersion: 88);

    expect(await db.query('ref_grille'), isEmpty);
    final sousPeriode = (await db.query('ref_sous_periode')).single;
    expect(sousPeriode['id'], 'sp1');
    expect(sousPeriode['rang'], isNull);
  });

  test('seul le curseur du bundle repart de zéro', () async {
    await migrateTenantDatabase(db, 87, newVersion: 88);

    final resources = [
      for (final r in await db.query('sync_meta')) r['resource']! as String,
    ];
    expect(
      resources,
      unorderedEquals(['academics_cours@u1', 'academics_grades_referential_x']),
    );
  });

  test('rejouer le palier ne casse rien', () async {
    await migrateTenantDatabase(db, 87, newVersion: 88);
    await expectLater(migrateTenantDatabase(db, 87, newVersion: 88), completes);
  });

  test('une base montée et une base neuve ont les mêmes colonnes', () async {
    await migrateTenantDatabase(db, 87, newVersion: 88);
    final fresh = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(fresh.close);
    await createOfflineSchema(fresh, buildOfflineSchema());

    expect(
      await columnsOf(db, 'ref_grille'),
      await columnsOf(fresh, 'ref_grille'),
    );
    expect(
      (await columnsOf(db, 'ref_sous_periode')).toSet(),
      (await columnsOf(fresh, 'ref_sous_periode')).toSet(),
    );
  });
}
