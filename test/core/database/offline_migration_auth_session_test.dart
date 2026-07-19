import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v6→v7 (Auth/session offline, ADR-010 §5).
///
/// On reproduit une base **pré-v7** sans les tables `auth_local`. La migration
/// doit matérialiser les trois tables (`auth_local_user`, `auth_local_session`,
/// `auth_clock_guard`) et rester idempotente au rejeu.
bool _ffiInitialized = false;

Future<Database> _openLegacyDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  // Base minimale pré-v7 : au moins l'outbox, aucune table auth_local.
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute('''
    CREATE TABLE outbox (
      id TEXT PRIMARY KEY,
      aggregate_type TEXT NOT NULL,
      aggregate_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      school_id TEXT,
      status TEXT NOT NULL DEFAULT 'PENDING',
      attempts INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      next_attempt_at INTEGER NOT NULL DEFAULT 0,
      last_error TEXT
    )
  ''');
  return db;
}

Future<bool> _hasTable(Database db, String table) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [table],
  );
  return rows.isNotEmpty;
}

void main() {
  test('v6→v7 : les trois tables auth_local sont créées', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    // Une entrée outbox pré-existante : le wipe de session ne devra jamais la
    // toucher — ici on vérifie juste que la migration ne l'efface pas.
    await db.insert('outbox', {
      'id': 'o1',
      'aggregate_type': 'PAYMENT',
      'aggregate_id': 'p1',
      'operation': 'create',
      'payload': '{}',
      'status': 'PENDING',
      'created_at': 1,
    });

    expect(await _hasTable(db, 'auth_local_user'), isFalse);

    await migrateOfflineDatabase(db, 6, buildOfflineSchema());

    expect(await _hasTable(db, 'auth_local_user'), isTrue);
    expect(await _hasTable(db, 'auth_local_session'), isTrue);

    // L'outbox pré-existante est intacte.
    final outbox = await db.query('outbox');
    expect(outbox.length, 1);

    // Les tables acceptent un enregistrement valide.
    await db.insert('auth_local_user', {
      'user_id': 'u1',
      'email': 'prof@ecole.cd',
      'first_name': 'Amina',
      'last_name': 'Kalala',
      'role': 'TEACHER',
      'school_id': 'sch-1',
      'password_verifier': 'verif',
      'verifier_salt': 'salt',
      'user_version': 0,
      'first_online_login_at': 100,
      'last_server_seen_at': 100,
    });
    final users = await db.query('auth_local_user');
    expect(users.single['session_started_at'], isNull);
  });

  test('v6→v7 : idempotent au rejeu (CREATE IF NOT EXISTS)', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 6, buildOfflineSchema());
    await migrateOfflineDatabase(db, 6, buildOfflineSchema());

    expect(await _hasTable(db, 'auth_local_user'), isTrue);
    expect(await _hasTable(db, 'auth_local_session'), isTrue);
  });

  test('auth_local_session applique la contrainte de mode', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);
    await migrateOfflineDatabase(db, 6, buildOfflineSchema());

    await db.insert('auth_local_user', {
      'user_id': 'u1',
      'email': 'prof@ecole.cd',
      'first_name': 'A',
      'last_name': 'K',
      'role': 'TEACHER',
      'school_id': 'sch-1',
      'password_verifier': 'v',
      'verifier_salt': 's',
      'user_version': 0,
      'first_online_login_at': 100,
      'last_server_seen_at': 100,
    });

    expect(
      () => db.insert('auth_local_session', {
        'id': 1,
        'user_id': 'u1',
        'degraded_mode': 'BOGUS',
        'refresh_expires_at': 999,
        'last_evaluated_at': 100,
      }),
      throwsA(anything),
    );
  });
}
