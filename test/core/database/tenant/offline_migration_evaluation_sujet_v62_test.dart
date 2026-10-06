import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/schema/academics_offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v62 — le sujet d'une évaluation, ses publications et le journal des
/// copies.
///
/// La table `evaluation` naît ici avec le DDL de la **v61** : une base montée
/// doit finir avec les colonnes d'une base créée à neuf.
const String _evaluationV61 = '''
  CREATE TABLE evaluation (
    id TEXT PRIMARY KEY,
    cours_id TEXT NOT NULL,
    type TEXT NOT NULL,
    eval_date INTEGER NOT NULL,
    max_points REAL NOT NULL,
    poids INTEGER NOT NULL,
    sous_periode_id TEXT,
    periode_scolaire_id TEXT,
    updated_at INTEGER NOT NULL,
    server_updated_at INTEGER,
    sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
    synced_at INTEGER,
    chapitre_ids_json TEXT NOT NULL DEFAULT '[]',
    rejection_code TEXT
  )
''';

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
    await db.execute(_evaluationV61);
    await db.insert('evaluation', {
      'id': 'e-1',
      'cours_id': 'c-1',
      'type': 'INTERRO',
      'eval_date': 0,
      'max_points': 10,
      'poids': 1,
      'updated_at': 1,
      'sync_status': 'SYNCED',
    });
  });
  tearDown(() => db.close());

  test(
    'les colonnes naissent, l’évaluation existante garde un sujet vide',
    () async {
      await migrateTenantDatabase(db, 61, newVersion: 62);

      final row = (await db.query('evaluation')).single;
      expect(row['titre'], isNull);
      expect(row['programme_json'], '[]');
      expect(row['sujet_questions_json'], '[]');
      expect(row['sujet_sync_status'], isNull);
      expect(row['publication_json'], isNull);
      expect(row['sync_status'], 'SYNCED');
      expect(await columnsOf(db, 'evaluation_copie_log'), contains('canal'));
    },
  );

  test('le palier se rejoue sans lever', () async {
    await migrateTenantDatabase(db, 61, newVersion: 62);
    await migrateTenantDatabase(db, 61, newVersion: 62);
    expect(await columnsOf(db, 'evaluation'), contains('titre'));
  });

  test('une base sans les notes traverse le palier', () async {
    final bare = await _openDb();
    await migrateTenantDatabase(bare, 61, newVersion: 62);
    expect(await columnsOf(bare, 'evaluation'), isEmpty);
    await bare.close();
  });

  test('base montée = base créée à neuf', () async {
    await migrateTenantDatabase(db, 61, newVersion: 62);
    final fresh = await _openDb();
    await fresh.execute(evaluationTable.createTableSql);
    await fresh.execute(evaluationCopieLogTable.createTableSql);
    for (final table in ['evaluation', 'evaluation_copie_log']) {
      expect(
        (await columnsOf(db, table))..sort(),
        (await columnsOf(fresh, table))..sort(),
        reason: table,
      );
    }
    await fresh.close();
  });
}
