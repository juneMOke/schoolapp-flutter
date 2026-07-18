import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v5→v6 (Discipline : agrégat {case, comments[]}).
///
/// On reproduit une base **pré-v6** : `disciplinary_cases` SANS `server_updated_at`
/// et SANS table `disciplinary_case_comments`. La migration doit créer la table
/// commentaires (append-only) et ajouter la colonne `server_updated_at`, sans
/// toucher les cas existants.
const String _legacyDisciplinaryCasesDdl = '''
  CREATE TABLE disciplinary_cases (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL,
    student_first_name TEXT NOT NULL,
    student_last_name TEXT NOT NULL,
    student_middle_name TEXT,
    student_gender TEXT NOT NULL DEFAULT 'OTHER',
    academic_year_id TEXT NOT NULL,
    disciplinary_case_date TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'DISRUPTIVE_BEHAVIOR',
    severity TEXT NOT NULL DEFAULT 'MINOR',
    status TEXT NOT NULL DEFAULT 'OPEN',
    sanction TEXT,
    version INTEGER,
    updated_at INTEGER NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
    synced_at INTEGER
  )
''';

bool _ffiInitialized = false;

Future<Database> _openLegacyDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute(_legacyDisciplinaryCasesDdl);
  return db;
}

Future<bool> _hasColumn(Database db, String table, String column) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.any((r) => r['name'] == column);
}

Future<bool> _hasTable(Database db, String table) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [table],
  );
  return rows.isNotEmpty;
}

Map<String, Object?> _legacyCase({required String id}) => {
  'id': id,
  'student_id': 's1',
  'student_first_name': 'Amina',
  'student_last_name': 'Kalala',
  'student_gender': 'FEMALE',
  'academic_year_id': 'ay-1',
  'disciplinary_case_date': '2026-05-04',
  'title': 'Incident réfectoire',
  'content': 'Bagarre au réfectoire',
  'status': 'OPEN',
  'updated_at': 100,
  'sync_status': 'SYNCED',
};

void main() {
  test('v5→v6 : table commentaires créée, server_updated_at ajouté, cas '
      'préservés', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    await db.insert('disciplinary_cases', _legacyCase(id: 'c1'));

    expect(await _hasTable(db, 'disciplinary_case_comments'), isFalse);
    expect(
      await _hasColumn(db, 'disciplinary_cases', 'server_updated_at'),
      isFalse,
    );

    await migrateOfflineDatabase(db, 5, buildOfflineSchema());

    // Table commentaires (append-only) matérialisée + colonne de visibilité.
    expect(await _hasTable(db, 'disciplinary_case_comments'), isTrue);
    expect(
      await _hasColumn(db, 'disciplinary_cases', 'server_updated_at'),
      isTrue,
    );

    // Le cas existant est intact ; la nouvelle colonne est nullable.
    final cases = await db.query('disciplinary_cases');
    expect(cases.length, 1);
    expect(cases.single['id'], 'c1');
    expect(cases.single['content'], 'Bagarre au réfectoire');
    expect(cases.single['server_updated_at'], isNull);

    // La table commentaires accepte un insert append-only.
    await db.insert('disciplinary_case_comments', {
      'id': 'cm1',
      'disciplinary_case_id': 'c1',
      'content': 'Convocation parents envoyée',
      'created_at': 200,
    });
    final comments = await db.query('disciplinary_case_comments');
    expect(comments.single['sync_status'], 'PENDING_SYNC');
  });

  test('v5→v6 : idempotent si relancé (aucune erreur, colonne unique)', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    await db.insert('disciplinary_cases', _legacyCase(id: 'c1'));

    await migrateOfflineDatabase(db, 5, buildOfflineSchema());
    // Rejeu : CREATE TABLE IF NOT EXISTS + garde _hasColumn → pas de double ALTER.
    await migrateOfflineDatabase(db, 5, buildOfflineSchema());

    expect(await _hasTable(db, 'disciplinary_case_comments'), isTrue);
    final info = await db.rawQuery('PRAGMA table_info(disciplinary_cases)');
    final serverUpdatedCols = info.where(
      (r) => r['name'] == 'server_updated_at',
    );
    expect(serverUpdatedCols.length, 1);
  });
}
