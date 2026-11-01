import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v77 — la saisie des notes par classe : trois tables neuves.
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

  Future<bool> hasTable(String name) async => (await db.rawQuery(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
    [name],
  )).isNotEmpty;

  test('les trois tables naissent, sans rien exiger de l\'existant', () async {
    await migrateTenantDatabase(db, 76, newVersion: 77);

    expect(await hasTable('cote_classe_cache'), isTrue);
    expect(await hasTable('cote_saisie'), isTrue);
    expect(await hasTable('ref_cote_cours'), isTrue);
  });

  test('v78 : `ref_cote_cours` gagne son identifiant serveur', () async {
    await migrateTenantDatabase(db, 76, newVersion: 77);
    await db.execute('DROP INDEX IF EXISTS idx_ref_cote_cours_id');
    await db.execute('ALTER TABLE ref_cote_cours DROP COLUMN id');

    await migrateTenantDatabase(db, 77, newVersion: 78);
    await migrateTenantDatabase(db, 77, newVersion: 78);

    final columns = await db.rawQuery('PRAGMA table_info(ref_cote_cours)');
    expect(columns.map((c) => c['name']), contains('id'));
  });

  test('rejouer le palier ne lève pas', () async {
    await migrateTenantDatabase(db, 76, newVersion: 77);
    await migrateTenantDatabase(db, 76, newVersion: 77);

    expect(await hasTable('cote_saisie'), isTrue);
  });
}
