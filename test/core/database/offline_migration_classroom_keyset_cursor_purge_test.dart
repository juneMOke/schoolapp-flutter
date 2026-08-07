import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v15→v16 : purge du curseur hérité `sync_meta.classrooms`
/// après le passage au pull KEYSET (CB-2 re-contracté). Une base v15 peut porter
/// un curseur au format ISO `updatedSince` de l'ancien contrat bundlé — envoyé
/// tel quel au nouvel endpoint keyset, il ne s'auto-guérirait que si le serveur
/// le rejette en 400. La migration purge donc ce curseur préventivement, sans
/// dépendre du serveur. `classroom_members` est une clé neuve : rien à purger.
bool _ffiInitialized = false;

Future<Database> _openV15Db() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute('''
    CREATE TABLE sync_meta (
      resource TEXT PRIMARY KEY,
      cursor TEXT,
      synced_at INTEGER
    )
  ''');
  return db;
}

void main() {
  test('v15→v16 : purge le curseur ISO hérité de classrooms', () async {
    final db = await _openV15Db();
    addTearDown(db.close);

    await db.insert('sync_meta', {
      'resource': 'classrooms',
      'cursor': '2026-07-20T08:00:00.000Z',
      'synced_at': 1,
    });
    // Ressources d'autres modules : ne doivent PAS être touchées.
    await db.insert('sync_meta', {
      'resource': 'classroom_transfers',
      'cursor': 'wm-transfers',
      'synced_at': 1,
    });
    await db.insert('sync_meta', {
      'resource': 'attendance',
      'cursor': 'wm-attendance',
      'synced_at': 1,
    });

    await migrateOfflineDatabase(db, 15, buildOfflineSchema());

    expect(
      await db.query(
        'sync_meta',
        where: 'resource = ?',
        whereArgs: ['classrooms'],
      ),
      isEmpty,
    );
    final untouched = await db.query(
      'sync_meta',
      where: 'resource IN (?, ?)',
      whereArgs: ['classroom_transfers', 'attendance'],
    );
    expect(untouched.length, 2);
  });

  test('v15→v16 : idempotent au rejeu', () async {
    final db = await _openV15Db();
    addTearDown(db.close);
    await db.insert('sync_meta', {
      'resource': 'classrooms',
      'cursor': '2026-07-20T08:00:00.000Z',
      'synced_at': 1,
    });

    await migrateOfflineDatabase(db, 15, buildOfflineSchema());
    await migrateOfflineDatabase(
      db,
      15,
      buildOfflineSchema(),
    ); // ne doit pas lever

    expect(
      await db.query(
        'sync_meta',
        where: 'resource = ?',
        whereArgs: ['classrooms'],
      ),
      isEmpty,
    );
  });

  test('base sans curseur classrooms préexistant : no-op propre', () async {
    final db = await _openV15Db();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 15, buildOfflineSchema());

    expect(await db.query('sync_meta'), isEmpty);
  });
}
