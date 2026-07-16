import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie `migrateOfflineDatabase` (le corps réel d'`onUpgrade`, extrait pour
/// être exerçable hors SQLCipher). Le vrai opener est chiffré et non ouvrable
/// en test ffi ; on drive donc la migration directement.
///
/// DDL `enrollments` **pré-v3** (sans `source_ref`) : reproduit une base
/// legacy v1/v2 sur laquelle l'ALTER doit ajouter la colonne.
const String _legacyEnrollmentsDdl = '''
  CREATE TABLE enrollments (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL,
    enrollment_type TEXT NOT NULL,
    status TEXT NOT NULL,
    academic_year_id TEXT NOT NULL,
    school_level_id TEXT,
    school_level_group_id TEXT,
    enrollment_date TEXT NOT NULL,
    enrollment_code TEXT,
    sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
    updated_at INTEGER NOT NULL DEFAULT 0
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
  await db.execute(_legacyEnrollmentsDdl);
  return db;
}

Future<bool> _hasColumn(Database db, String table, String column) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.any((r) => r['name'] == column);
}

void main() {
  test(
    'v2→v3 : ALTER ajoute source_ref, données existantes préservées',
    () async {
      final db = await _openLegacyDb();
      addTearDown(db.close);

      await db.insert('enrollments', {
        'id': 'e1',
        'student_id': 's1',
        'enrollment_type': 'NEW_ENROLLMENT',
        'status': 'IN_PROGRESS',
        'academic_year_id': 'ay-1',
        'enrollment_date': '2026-07-01',
        'sync_status': 'SYNCED',
        'updated_at': 100,
      });

      expect(await _hasColumn(db, 'enrollments', 'source_ref'), isFalse);

      // v2 : le bloc oldVersion<2 est sauté (ref_* déjà présentes) ; seul l'ALTER
      // v3 s'applique.
      await migrateOfflineDatabase(db, 2, buildOfflineSchema());

      expect(await _hasColumn(db, 'enrollments', 'source_ref'), isTrue);
      final row = (await db.query('enrollments')).single;
      expect(row['id'], 'e1'); // ligne legacy préservée
      expect(row['source_ref'], isNull); // NULL par défaut

      // La nouvelle colonne est écrivable.
      await db.update(
        'enrollments',
        {'source_ref': 'KIN-2025-0001'},
        where: 'id = ?',
        whereArgs: ['e1'],
      );
      expect(
        (await db.query('enrollments')).single['source_ref'],
        'KIN-2025-0001',
      );
    },
  );

  test('v1→v3 : crée les tables de référence ET ajoute source_ref', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    // Une base v1 n'a pas encore les tables de référence Inscription.
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND "
        "name='ref_previous_year_students'",
      ),
      isEmpty,
    );

    await migrateOfflineDatabase(db, 1, buildOfflineSchema());

    // v2 : tables de référence créées.
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND "
        "name='ref_previous_year_students'",
      ),
      isNotEmpty,
    );
    // v3 : source_ref ajoutée sur l'enrollments legacy conservée.
    expect(await _hasColumn(db, 'enrollments', 'source_ref'), isTrue);
  });
}
