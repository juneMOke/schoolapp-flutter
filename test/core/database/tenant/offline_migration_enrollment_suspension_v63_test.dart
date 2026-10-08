import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/schema/editique_offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v63 — la désactivation d'élèves.
///
/// École : `enrollment_suspensions` naît. Appareil : le cache éditique admet la
/// fiche `FI`, table reconstruite AVEC copie.
const String _editiqueCacheV62 = '''
  CREATE TABLE editique_cache_entries (
    id TEXT PRIMARY KEY,
    document_id TEXT,
    document_number TEXT,
    doc_type TEXT NOT NULL,
    student_id TEXT,
    academic_year_id TEXT,
    school_id TEXT NOT NULL,
    owner_uid TEXT NOT NULL DEFAULT '',
    size_bytes INTEGER NOT NULL,
    content_sha256 TEXT,
    emitted_at INTEGER,
    cancelled_at INTEGER,
    cancellation_reason TEXT,
    created_at INTEGER NOT NULL,
    last_accessed_at INTEGER NOT NULL,
    CHECK (
      COALESCE(NULLIF(document_id, ''), NULLIF(document_number, ''))
        IS NOT NULL
    ),
    CHECK (doc_type IN ('AI', 'NP', 'RC', 'BU'))
  )
''';

Future<Database> _openDb() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(singleInstance: false),
);

Map<String, Object?> _cacheRow(String id, String docType) => {
  'id': id,
  'document_id': 'doc-$id',
  'doc_type': docType,
  'school_id': 'school-1',
  'size_bytes': 10,
  'content_sha256': 'sha-$id',
  'cancelled_at': 7,
  'created_at': 1,
  'last_accessed_at': 2,
};

void main() {
  sqfliteFfiInit();

  group('école', () {
    late Database db;
    setUp(() async => db = await _openDb());
    tearDown(() => db.close());

    Future<bool> hasTable() async => (await db.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type='table' "
      "AND name='enrollment_suspensions'",
    )).isNotEmpty;

    test('la table naît, rejouable', () async {
      await migrateTenantDatabase(db, 62, newVersion: 63);
      await migrateTenantDatabase(db, 62, newVersion: 63);
      expect(await hasTable(), isTrue);
    });

    test('une seule période ouverte par inscription', () async {
      await migrateTenantDatabase(db, 62, newVersion: 63);
      Map<String, Object?> row(String id, {String? reactivatedAt}) => {
        'id': id,
        'school_id': 'school-1',
        'enrollment_id': 'enr-1',
        'student_id': 'stu-1',
        'academic_year_id': 'y-1',
        'suspended_at': '2026-10-08T08:00:00Z',
        'reactivated_at': reactivatedAt,
        'updated_at': 1,
      };
      await db.insert(
        'enrollment_suspensions',
        row('a', reactivatedAt: '2026-10-09T08:00:00Z'),
      );
      await db.insert('enrollment_suspensions', row('b'));
      expect(
        () => db.insert('enrollment_suspensions', row('c')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('appareil', () {
    late Database db;
    setUp(() async {
      db = await _openDb();
      await db.execute(_editiqueCacheV62);
      await db.insert('editique_cache_entries', _cacheRow('1', 'AI'));
    });
    tearDown(() => db.close());

    test('les lignes sont copiées, FI est admis', () async {
      await migrateDeviceDatabase(db, 62, newVersion: 63);

      final rows = await db.query('editique_cache_entries');
      expect(rows.single['content_sha256'], 'sha-1');
      expect(rows.single['cancelled_at'], 7);
      await db.insert('editique_cache_entries', _cacheRow('2', 'FI'));
      expect(
        () => db.insert('editique_cache_entries', _cacheRow('3', 'XX')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejouable, index canoniques recréés', () async {
      await migrateDeviceDatabase(db, 62, newVersion: 63);
      await migrateDeviceDatabase(db, 62, newVersion: 63);

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' "
        "AND tbl_name='editique_cache_entries' AND sql IS NOT NULL",
      );
      expect(
        indexes.map((r) => r['name']),
        containsAll(<String>[
          'idx_editique_cache_document',
          'idx_editique_cache_number',
          'idx_editique_cache_subject',
          'idx_editique_cache_lru',
        ]),
      );
      expect(editiqueCacheEntriesTable.createIndexSql, hasLength(4));
    });
  });
}
