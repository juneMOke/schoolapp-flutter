import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/schema/student_photo_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v60 — l'empreinte de la vignette d'une photo d'élève.
///
/// La table naît ici avec le DDL de la **v59** : une base montée doit finir
/// avec les colonnes d'une base créée à neuf.
const String _studentPhotosV59 = '''
  CREATE TABLE student_photos (
    student_id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL,
    sha256 TEXT,
    taken_at TEXT,
    server_updated_at TEXT,
    pending_op TEXT,
    pending_sha256 TEXT,
    pending_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'SYNCED',
    sync_error TEXT,
    sync_error_code TEXT,
    cached_96_sha TEXT,
    cached_512_sha TEXT,
    updated_at INTEGER NOT NULL
  )
''';

Future<Database> _openDb() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(singleInstance: false),
);

void main() {
  sqfliteFfiInit();

  late Database db;

  Future<List<String>> columnsOf(Database on) async => [
    for (final row in await on.rawQuery('PRAGMA table_info(student_photos)'))
      row['name'] as String,
  ];

  setUp(() async {
    db = await _openDb();
    await db.execute(_studentPhotosV59);
    await db.insert('student_photos', {
      'student_id': 's-1',
      'school_id': 'school-1',
      'sha256': 'sha-a',
      'cached_96_sha': 'sha-a',
      'updated_at': 1,
    });
  });
  tearDown(() => db.close());

  test('la colonne naît, la ligne existante la porte vide', () async {
    await migrateTenantDatabase(db, 59, newVersion: 60);

    expect(await columnsOf(db), contains('thumbnail_sha256'));
    final row = (await db.query('student_photos')).single;
    expect(row['thumbnail_sha256'], isNull);
    expect(row['cached_96_sha'], 'sha-a');
  });

  test('le palier se rejoue sans lever', () async {
    await migrateTenantDatabase(db, 59, newVersion: 60);
    await migrateTenantDatabase(db, 59, newVersion: 60);
    expect(await columnsOf(db), contains('thumbnail_sha256'));
  });

  test('base montée = base créée à neuf', () async {
    await migrateTenantDatabase(db, 59, newVersion: 60);
    final fresh = await _openDb();
    await fresh.execute(studentPhotosTable.createTableSql);
    expect((await columnsOf(db))..sort(), (await columnsOf(fresh))..sort());
    await fresh.close();
  });
}
