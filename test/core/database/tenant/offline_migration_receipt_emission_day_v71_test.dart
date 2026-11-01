import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v71 — `generated_documents.emitted_on`, le jour d'émission du reçu
/// scellé. Additif et nullable : les lignes d'avant restent sans jour.
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

  Future<List<String>> columns() async => [
    for (final row in await db.rawQuery(
      'PRAGMA table_info(generated_documents)',
    ))
      row['name'] as String,
  ];

  test(
    'la colonne s ajoute, les lignes existantes restent sans jour',
    () async {
      await db.execute('''
      CREATE TABLE generated_documents (
        id TEXT PRIMARY KEY,
        number TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PROVISIONAL'
      )
    ''');
      await db.insert('generated_documents', {
        'id': 'd-1',
        'number': 'CF-RC-2627-000001',
        'status': 'DEFINITIVE',
      });

      await migrateTenantDatabase(db, 70, newVersion: 71);

      expect(await columns(), contains('emitted_on'));
      final rows = await db.query('generated_documents');
      expect(rows.single['emitted_on'], isNull);
    },
  );

  test('rejoué, le palier ne lève pas', () async {
    await db.execute(
      'CREATE TABLE generated_documents (id TEXT PRIMARY KEY, '
      'emitted_on TEXT)',
    );

    await migrateTenantDatabase(db, 70, newVersion: 71);

    expect(await columns(), contains('emitted_on'));
  });

  test('sans la table, le palier passe sans rien créer', () async {
    await migrateTenantDatabase(db, 70, newVersion: 71);

    expect(await columns(), isEmpty);
  });
}
