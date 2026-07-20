import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie les migrations auth (ADR-010 §5) : v6→v7 (création des deux tables
/// `auth_local_user` + `auth_local_session` — l'anti-triche horloge n'a pas de
/// table, par design) et v9→v10 (borne offline par utilisateur, amendement m4).
/// Chaque étape doit rester idempotente au rejeu.
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

  test(
    'v9→v10 : borne offline par utilisateur, backfill depuis la session active',
    () async {
      final db = await _openLegacyDb();
      addTearDown(db.close);

      // Base v9 : tables auth_local au format SANS `refresh_expires_at`.
      await db.execute('''
        CREATE TABLE auth_local_user (
          user_id               TEXT PRIMARY KEY,
          email                 TEXT NOT NULL UNIQUE COLLATE NOCASE,
          first_name            TEXT NOT NULL,
          last_name             TEXT NOT NULL,
          role                  TEXT NOT NULL,
          school_id             TEXT NOT NULL,
          password_verifier     TEXT NOT NULL,
          verifier_salt         TEXT NOT NULL,
          user_version          INTEGER NOT NULL,
          first_online_login_at INTEGER NOT NULL,
          last_server_seen_at   INTEGER NOT NULL,
          session_started_at    INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE auth_local_session (
          id                 INTEGER PRIMARY KEY CHECK (id = 1),
          user_id            TEXT NOT NULL REFERENCES auth_local_user(user_id),
          degraded_mode      TEXT NOT NULL DEFAULT 'NORMAL',
          refresh_expires_at INTEGER NOT NULL,
          last_evaluated_at  INTEGER NOT NULL
        )
      ''');
      Map<String, Object?> userRow(String id, String email) => {
        'user_id': id,
        'email': email,
        'first_name': 'A',
        'last_name': 'K',
        'role': 'TEACHER',
        'school_id': 'sch-1',
        'password_verifier': 'v',
        'verifier_salt': 's',
        'user_version': 0,
        'first_online_login_at': 100,
        'last_server_seen_at': 100,
      };
      await db.insert('auth_local_user', userRow('u1', 'a@ecole.cd'));
      await db.insert('auth_local_user', userRow('u2', 'b@ecole.cd'));
      await db.insert('auth_local_session', {
        'id': 1,
        'user_id': 'u1',
        'degraded_mode': 'NORMAL',
        'refresh_expires_at': 777777,
        'last_evaluated_at': 100,
      });

      await migrateOfflineDatabase(db, 9, buildOfflineSchema());

      // Le propriétaire de la session active hérite de sa borne ; les autres
      // comptes restent sans fenêtre (reconnexion online exigée).
      final users = await db.query('auth_local_user', orderBy: 'user_id');
      expect(users[0]['refresh_expires_at'], 777777);
      expect(users[1]['refresh_expires_at'], isNull);

      // Idempotent au rejeu (colonne déjà présente → ALTER ET backfill sautés) :
      // u2 doit RESTER sans fenêtre — si le backfill re-tournait, l'assert sur
      // u1 seul ne le détecterait pas.
      await migrateOfflineDatabase(db, 9, buildOfflineSchema());
      final replayed = await db.query('auth_local_user', orderBy: 'user_id');
      expect(replayed[0]['refresh_expires_at'], 777777);
      expect(replayed[1]['refresh_expires_at'], isNull);
    },
  );

  test(
    'v9→v10 : session vide (agent déconnecté à la mise à jour) → bornes NULL',
    () async {
      final db = await _openLegacyDb();
      addTearDown(db.close);

      // Cas de flotte le plus probable : l'app est mise à jour hors session
      // (le logout pré-v10 supprimait la ligne singleton). Toutes les bornes
      // restent NULL → login offline refusé jusqu'à un contact online. La
      // promesse m4 « login offline après logout » n'est PAS rétroactive.
      await db.execute('''
        CREATE TABLE auth_local_user (
          user_id               TEXT PRIMARY KEY,
          email                 TEXT NOT NULL UNIQUE COLLATE NOCASE,
          first_name            TEXT NOT NULL,
          last_name             TEXT NOT NULL,
          role                  TEXT NOT NULL,
          school_id             TEXT NOT NULL,
          password_verifier     TEXT NOT NULL,
          verifier_salt         TEXT NOT NULL,
          user_version          INTEGER NOT NULL,
          first_online_login_at INTEGER NOT NULL,
          last_server_seen_at   INTEGER NOT NULL,
          session_started_at    INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE auth_local_session (
          id                 INTEGER PRIMARY KEY CHECK (id = 1),
          user_id            TEXT NOT NULL REFERENCES auth_local_user(user_id),
          degraded_mode      TEXT NOT NULL DEFAULT 'NORMAL',
          refresh_expires_at INTEGER NOT NULL,
          last_evaluated_at  INTEGER NOT NULL
        )
      ''');
      await db.insert('auth_local_user', {
        'user_id': 'u1',
        'email': 'a@ecole.cd',
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

      await migrateOfflineDatabase(db, 9, buildOfflineSchema());

      final users = await db.query('auth_local_user');
      expect(users.single['refresh_expires_at'], isNull);
    },
  );

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
