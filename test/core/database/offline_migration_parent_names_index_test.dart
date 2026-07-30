import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v16→v17 : index composé `parents(last_name,
/// first_name)` pour accélérer la recherche de tuteur existant (étape
/// Tuteurs, popin "Rechercher un parent"). Pas de UNIQUE INDEX sur
/// `phone_number` : l'unicité reste applicative (DAO) pour ne pas risquer de
/// casser la migration sur des doublons hérités.
bool _ffiInitialized = false;

Future<Database> _openV16Db() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  // Base v16 : `parents` SANS l'index composé nom/prénom.
  await db.execute('''
    CREATE TABLE parents (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      surname TEXT,
      phone_number TEXT NOT NULL,
      email TEXT,
      identification_number TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      synced_at INTEGER,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('CREATE INDEX idx_parents_phone ON parents(phone_number)');
  return db;
}

Future<Set<String>> _indexNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'index'",
  );
  return rows.map((r) => r['name'] as String).toSet();
}

void main() {
  test('v16→v17 : crée idx_parents_names', () async {
    final db = await _openV16Db();
    addTearDown(db.close);

    expect(await _indexNames(db), isNot(contains('idx_parents_names')));

    await migrateOfflineDatabase(db, 16, buildOfflineSchema());

    expect(await _indexNames(db), contains('idx_parents_names'));
    // Aucun UNIQUE INDEX sur phone_number : unicité volontairement applicative.
    final phoneIndexInfo = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type = 'index' AND name = 'idx_parents_phone'",
    );
    expect(phoneIndexInfo.single['sql'], isNot(contains('UNIQUE')));
  });

  test('v16→v17 : idempotent au rejeu', () async {
    final db = await _openV16Db();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 16, buildOfflineSchema());
    await migrateOfflineDatabase(
      db,
      16,
      buildOfflineSchema(),
    ); // ne doit pas lever

    expect(await _indexNames(db), contains('idx_parents_names'));
  });

  test('base sans table parents préexistante : no-op propre', () async {
    if (!_ffiInitialized) {
      sqfliteFfiInit();
      _ffiInitialized = true;
    }
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 16, buildOfflineSchema());

    expect(await _indexNames(db), isNot(contains('idx_parents_names')));
  });
}
