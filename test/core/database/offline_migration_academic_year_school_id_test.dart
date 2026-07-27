import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v12→v13 : `ref_academic_years.school_id` (le module
/// `bootstrap`, cache Hive online-only, est remplacé par le référentiel
/// offline déjà pullé pour Inscription — décision FRONT 2026-07-26). Colonne
/// stampée côté client (jamais attendue du payload serveur) ; backfill
/// best-effort depuis l'utilisateur de la session active.
bool _ffiInitialized = false;

Future<Database> _openLegacyDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  // Base v12 : `ref_academic_years` SANS `school_id`.
  await db.execute('''
    CREATE TABLE ref_academic_years (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      start_date TEXT,
      end_date TEXT,
      is_current INTEGER NOT NULL DEFAULT 0,
      synced_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
  return db;
}

Future<bool> _hasColumn(Database db, String table, String column) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  return info.any((row) => row['name'] == column);
}

void main() {
  test(
    'v12→v13 : colonne ajoutée + backfill depuis la session active',
    () async {
      final db = await _openLegacyDb();
      addTearDown(db.close);

      await db.insert('ref_academic_years', {
        'id': 'ay-1',
        'name': '2026',
        'is_current': 1,
        'synced_at': 1,
      });

      // Deux comptes locaux (device partagé), un seul avec une session active
      // (singleton `auth_local_session.id = 1`) — c'est SON school_id qui
      // doit servir au backfill.
      await db.execute('''
        CREATE TABLE auth_local_user (
          user_id TEXT PRIMARY KEY,
          school_id TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE auth_local_session (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          user_id TEXT NOT NULL REFERENCES auth_local_user(user_id)
        )
      ''');
      await db.insert('auth_local_user', {
        'user_id': 'u1',
        'school_id': 'sch-1',
      });
      await db.insert('auth_local_user', {
        'user_id': 'u2',
        'school_id': 'sch-2',
      });
      await db.insert('auth_local_session', {'id': 1, 'user_id': 'u1'});

      expect(await _hasColumn(db, 'ref_academic_years', 'school_id'), isFalse);

      await migrateOfflineDatabase(db, 12, buildOfflineSchema());

      expect(await _hasColumn(db, 'ref_academic_years', 'school_id'), isTrue);
      final rows = await db.query('ref_academic_years');
      expect(rows.single['school_id'], 'sch-1');
    },
  );

  test('v12→v13 : aucune session active → school_id reste vide', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    await db.insert('ref_academic_years', {
      'id': 'ay-1',
      'name': '2026',
      'is_current': 1,
      'synced_at': 1,
    });
    // Ni `auth_local_user` ni `auth_local_session` : device jamais migré avec
    // une session vivante (cas de flotte le plus probable au déploiement).

    await migrateOfflineDatabase(db, 12, buildOfflineSchema());

    final rows = await db.query('ref_academic_years');
    expect(rows.single['school_id'], '');
  });

  test('v12→v13 : idempotent au rejeu (ALTER + backfill sautés)', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);
    await db.insert('ref_academic_years', {
      'id': 'ay-1',
      'name': '2026',
      'is_current': 1,
      'synced_at': 1,
    });
    await db.execute('''
      CREATE TABLE auth_local_user (
        user_id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE auth_local_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id TEXT NOT NULL REFERENCES auth_local_user(user_id)
      )
    ''');
    await db.insert('auth_local_user', {'user_id': 'u1', 'school_id': 'sch-1'});
    await db.insert('auth_local_session', {'id': 1, 'user_id': 'u1'});

    await migrateOfflineDatabase(db, 12, buildOfflineSchema());
    // Rejeu : la colonne existe déjà → ALTER/backfill sautés (idempotent).
    // On change le school_id du compte APRÈS le premier passage : s'il
    // re-tournait, la ligne serait écrasée par 'sch-1-bis'.
    await db.update(
      'auth_local_user',
      {'school_id': 'sch-1-bis'},
      where: 'user_id = ?',
      whereArgs: ['u1'],
    );
    await migrateOfflineDatabase(db, 12, buildOfflineSchema());

    final rows = await db.query('ref_academic_years');
    expect(rows.single['school_id'], 'sch-1');
  });
}
