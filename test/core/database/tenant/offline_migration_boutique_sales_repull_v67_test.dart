import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v67 — les ventes boutique redescendent une fois, pour rapporter le
/// numéro de reçu que le poste ignorait.
void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute(
      'CREATE TABLE sync_meta (resource TEXT PRIMARY KEY, cursor TEXT)',
    );
    for (final resource in [
      'boutique_sales@E1',
      'boutique_sales',
      'boutique_catalog@E1',
      'classrooms',
    ]) {
      await db.insert('sync_meta', {'resource': resource, 'cursor': 'c'});
    }
  });
  tearDown(() => db.close());

  Future<List<String>> resources() async => [
    for (final row in await db.query('sync_meta', orderBy: 'resource'))
      row['resource'] as String,
  ];

  test('le curseur des ventes est effacé, et lui seul', () async {
    await migrateTenantDatabase(db, 66, newVersion: 67);

    // Le catalogue partage le préfixe `boutique_` : il ne doit pas repartir.
    expect(await resources(), ['boutique_catalog@E1', 'classrooms']);
  });

  test('une base déjà en v67 n\'est pas re-tirée', () async {
    await migrateTenantDatabase(db, 67, newVersion: 67);

    expect(await resources(), hasLength(4));
  });

  test('une base sans curseurs traverse le palier sans lever', () async {
    await db.execute('DROP TABLE sync_meta');

    await migrateTenantDatabase(db, 66, newVersion: 67);
  });
}
