import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v7→v8 (Notes / Cours — academics + schedule, ADR-006).
///
/// On reproduit une base **pré-v8** sans les tables Notes/Cours. La migration
/// doit matérialiser les cinq tables (`ref_time_slots`, `ref_recurring_sessions`,
/// `ref_cours`, `evaluation`, `note_evaluation`), rester idempotente au rejeu, et
/// appliquer la clé naturelle `(evaluation_id, student_id)` sur `note_evaluation`.
bool _ffiInitialized = false;

Future<Database> _openLegacyDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  // Base minimale pré-v8 : au moins l'outbox, aucune table Notes/Cours.
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

const _academicsTables = [
  'ref_time_slots',
  'ref_recurring_sessions',
  'ref_cours',
  'evaluation',
  'note_evaluation',
];

void main() {
  test('v7→v8 : les cinq tables Notes/Cours sont créées', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    // Une entrée outbox pré-existante : la migration ne doit jamais la toucher.
    await db.insert('outbox', {
      'id': 'o1',
      'aggregate_type': 'PAYMENT',
      'aggregate_id': 'p1',
      'operation': 'create',
      'payload': '{}',
      'status': 'PENDING',
      'created_at': 1,
    });

    for (final t in _academicsTables) {
      expect(await _hasTable(db, t), isFalse, reason: '$t absente en pré-v8');
    }

    await migrateOfflineDatabase(db, 7, buildOfflineSchema());

    for (final t in _academicsTables) {
      expect(await _hasTable(db, t), isTrue, reason: '$t créée en v8');
    }

    // L'outbox pré-existante est intacte.
    expect((await db.query('outbox')).length, 1);
  });

  test('v7→v8 : idempotent au rejeu (CREATE IF NOT EXISTS)', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 7, buildOfflineSchema());
    await migrateOfflineDatabase(db, 7, buildOfflineSchema());

    for (final t in _academicsTables) {
      expect(await _hasTable(db, t), isTrue);
    }
  });

  test('evaluation (régime A) et note_evaluation (régime C) acceptent une '
      'ligne valide', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);
    await migrateOfflineDatabase(db, 7, buildOfflineSchema());

    await db.insert('evaluation', {
      'id': 'ev-1',
      'cours_id': 'c-1',
      'type': 'INTERRO',
      'eval_date': 1000,
      'max_points': 20.0,
      'poids': 1,
      'sous_periode_id': 'sp-1',
      'updated_at': 1000,
    });
    await db.insert('note_evaluation', {
      'id': 'n-1',
      'evaluation_id': 'ev-1',
      'student_id': 'stu-1',
      'points_obtenus': 15.5,
      'statut': 'NOTEE',
      'updated_at': 1000,
    });

    expect(
      (await db.query('evaluation')).single['sync_status'],
      'PENDING_SYNC',
    );
    expect((await db.query('note_evaluation')).single['points_obtenus'], 15.5);
  });

  test(
    'note_evaluation applique la clé naturelle (evaluation_id, student_id)',
    () async {
      final db = await _openLegacyDb();
      addTearDown(db.close);
      await migrateOfflineDatabase(db, 7, buildOfflineSchema());

      await db.insert('note_evaluation', {
        'id': 'n-1',
        'evaluation_id': 'ev-1',
        'student_id': 'stu-1',
        'statut': 'NOTEE',
        'points_obtenus': 12.0,
        'updated_at': 1000,
      });

      // Même (evaluation_id, student_id) avec un id de transport différent → viole
      // la contrainte UNIQUE (le vrai chemin d'écriture passe par un UPSERT).
      expect(
        () => db.insert('note_evaluation', {
          'id': 'n-2',
          'evaluation_id': 'ev-1',
          'student_id': 'stu-1',
          'statut': 'ABSENT_JUSTIFIE',
          'updated_at': 2000,
        }),
        throwsA(anything),
      );
    },
  );
}
