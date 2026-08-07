import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v13→v14 : table `ref_school` (identité du tenant),
/// le bundle référentiel renvoyant désormais `school` + `current`/`previous`
/// au lieu d'une liste plate d'années. Table neuve, aucun backfill.
bool _ffiInitialized = false;

Future<Database> _openLegacyDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
}

Future<bool> _hasTable(Database db, String table) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [table],
  );
  return rows.isNotEmpty;
}

void main() {
  test('v13→v14 : table ref_school créée', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    expect(await _hasTable(db, 'ref_school'), isFalse);

    await migrateOfflineDatabase(db, 13, buildOfflineSchema());

    expect(await _hasTable(db, 'ref_school'), isTrue);
    await db.insert('ref_school', {
      'id': 'sch-1',
      'name': 'Ecole Etoile',
      'synced_at': 1,
    });
    final rows = await db.query('ref_school');
    expect(rows.single['id'], 'sch-1');
  });

  test('v13→v14 : idempotent si relancé (aucune erreur)', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 13, buildOfflineSchema());
    // Rejeu : CREATE TABLE IF NOT EXISTS → pas d'erreur, table déjà présente.
    await migrateOfflineDatabase(db, 13, buildOfflineSchema());

    expect(await _hasTable(db, 'ref_school'), isTrue);
  });
}
