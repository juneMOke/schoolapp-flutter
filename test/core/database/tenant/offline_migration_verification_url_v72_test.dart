import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v72 — l'URL de vérification du reçu scellé, imprimée en QR : une
/// colonne côté école, une côté appareil. Additive et nullable : les lignes
/// d'avant restent sans URL, donc sans QR.
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

  test('école : la colonne s ajoute, les lignes restent sans URL', () async {
    await db.execute(
      'CREATE TABLE generated_documents (id TEXT PRIMARY KEY, number TEXT)',
    );
    await db.insert('generated_documents', {'id': 'd-1', 'number': 'RC-1'});

    await migrateTenantDatabase(db, 71, newVersion: 72);

    expect(await columns('generated_documents'), contains('verification_url'));
    final rows = await db.query('generated_documents');
    expect(rows.single['verification_url'], isNull);
  });

  test('appareil : le cache des pièces gagne la colonne', () async {
    await db.execute(
      'CREATE TABLE editique_cache_entries (id TEXT PRIMARY KEY)',
    );

    await migrateDeviceDatabase(db, 71, newVersion: 72);

    expect(
      await columns('editique_cache_entries'),
      contains('verification_url'),
    );
  });

  test('rejoué, ou sans la table, le palier ne lève pas', () async {
    await db.execute(
      'CREATE TABLE generated_documents (id TEXT PRIMARY KEY, '
      'verification_url TEXT)',
    );

    await migrateTenantDatabase(db, 71, newVersion: 72);
    await migrateDeviceDatabase(db, 71, newVersion: 72);

    expect(await columns('editique_cache_entries'), isEmpty);
  });
}
