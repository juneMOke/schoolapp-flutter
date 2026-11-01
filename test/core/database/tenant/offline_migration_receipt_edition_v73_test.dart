import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v73 — la numérotation par édition (V200 du back) : deux pièces
/// peuvent partager un numéro, et l'unicité ne vaut plus que sans identifiant.
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

  Future<List<String>> columns(String table) async => [
    for (final row in await db.rawQuery('PRAGMA table_info($table)'))
      row['name'] as String,
  ];

  Future<void> createV72Cache() async {
    await db.execute(
      'CREATE TABLE editique_cache_entries (id TEXT PRIMARY KEY, '
      'document_id TEXT, document_number TEXT, school_id TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_editique_cache_number '
      'ON editique_cache_entries(school_id, document_number)',
    );
    await db.insert('editique_cache_entries', {
      'id': 'c-1',
      'document_id': 'doc-1',
      'document_number': 'RC-1',
      'school_id': 's-1',
    });
  }

  test('école : generated_documents gagne l édition', () async {
    await db.execute(
      'CREATE TABLE generated_documents (id TEXT PRIMARY KEY, number TEXT)',
    );

    await migrateTenantDatabase(db, 72, newVersion: 73);

    expect(await columns('generated_documents'), contains('edition'));
  });

  test('appareil : deux pièces identifiées partagent un numéro', () async {
    await createV72Cache();

    await migrateDeviceDatabase(db, 72, newVersion: 73);

    expect(await columns('editique_cache_entries'), contains('edition'));
    await db.insert('editique_cache_entries', {
      'id': 'c-2',
      'document_id': 'doc-2',
      'document_number': 'RC-1',
      'school_id': 's-1',
    });
    expect(await db.query('editique_cache_entries'), hasLength(2));
  });

  test('appareil : sans identifiant, le numéro reste unique', () async {
    await createV72Cache();
    await migrateDeviceDatabase(db, 72, newVersion: 73);

    Future<int> insertUnidentified(String id) => db.insert(
      'editique_cache_entries',
      {'id': id, 'document_number': 'RC-2', 'school_id': 's-1'},
    );

    await insertUnidentified('c-2');
    await expectLater(
      insertUnidentified('c-3'),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('rejoué, ou sans la table, le palier ne lève pas', () async {
    await migrateDeviceDatabase(db, 72, newVersion: 73);
    await createV72Cache();
    await migrateDeviceDatabase(db, 72, newVersion: 73);
    await migrateDeviceDatabase(db, 72, newVersion: 73);

    expect(await columns('editique_cache_entries'), contains('edition'));
  });
}
