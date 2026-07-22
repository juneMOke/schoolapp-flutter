import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v10→v11 : purge + rebootstrap forcé des données
/// Notes/Cours après le passage au contrat back scopé enseignant (commit
/// `1ec6be3`, DF-K/DF-L). Une base v10 peut porter des cours/évaluations/notes/
/// séances d'AUTRES enseignants (pulls antérieurs non scopés) — la migration
/// doit tout vider (données + curseurs `sync_meta` + outbox académique) sans
/// toucher aux données d'autres modules (auth, outbox non-académique).
bool _ffiInitialized = false;

Future<Database> _openV10Db() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
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
  test(
    'v10→v11 : purge ref_cours/evaluation/note_evaluation/'
    'ref_recurring_sessions + curseurs sync_meta + outbox académique',
    () async {
      final db = await _openV10Db();
      addTearDown(db.close);

      // Base v10 = academics/schedule déjà matérialisées (v8/v9), contaminées
      // par un pull antérieur non scopé enseignant.
      await migrateOfflineDatabase(db, 7, buildOfflineSchema());

      await db.insert('ref_cours', {
        'id': 'co-other-teacher',
        'classroom_id': 'c1',
        'ligne_bareme_id': 'lb-1',
        'synced_at': 1,
      });
      await db.insert('ref_cours_notation', {
        'cours_id': 'co-other-teacher',
        'classroom_id': 'c1',
        'branche_nom': 'Maths',
        'effectif': 30,
        'periodes_json': '[]',
        'synced_at': 1,
      });
      await db.insert('evaluation', {
        'id': 'ev-1',
        'cours_id': 'co-other-teacher',
        'type': 'INTERRO',
        'eval_date': 1,
        'max_points': 20.0,
        'poids': 1,
        'updated_at': 1,
        'sync_status': 'SYNCED',
      });
      await db.insert('note_evaluation', {
        'id': 'n-1',
        'evaluation_id': 'ev-1',
        'student_id': 's1',
        'points_obtenus': 12.0,
        'statut': 'NOTEE',
        'updated_at': 1,
        'sync_status': 'SYNCED',
      });
      await db.insert('ref_recurring_sessions', {
        'id': 's1',
        'academic_year_id': 'ay-1',
        'cours_id': 'co-other-teacher',
        'time_slot_id': 't1',
        'day_of_week': 'MON',
        'teacher_id': 'someone-else',
        'classroom_id': 'c1',
        'teacher_label': 'M. Autre',
        'classroom_label': '3e A',
        'subject_label': 'Maths',
        'synced_at': 1,
      });
      await db.insert('sync_meta', {
        'resource': 'academics_cours',
        'cursor': 'wm-old',
        'synced_at': 1,
      });
      await db.insert('sync_meta', {
        'resource': 'academics_evaluations:co-other-teacher',
        'cursor': 'wm-old-eval',
        'synced_at': 1,
      });
      await db.insert('sync_meta', {
        'resource': 'schedule_sessions',
        'cursor': 'wm-old-sessions',
        'synced_at': 1,
      });
      await db.insert('outbox', {
        'id': 'obx-1',
        'aggregate_type': 'ACADEMICS_EVALUATION',
        'aggregate_id': 'ev-1',
        'operation': 'create',
        'payload': '{}',
        'status': 'PENDING',
        'created_at': 1,
      });
      // Outbox d'un autre module : ne doit PAS être touchée.
      await db.insert('outbox', {
        'id': 'obx-other',
        'aggregate_type': 'PAYMENT',
        'aggregate_id': 'p1',
        'operation': 'create',
        'payload': '{}',
        'status': 'PENDING',
        'created_at': 1,
      });
      // Ressource sync_meta d'un autre module : ne doit PAS être touchée.
      await db.insert('sync_meta', {
        'resource': 'schedule_time_slots',
        'cursor': 'wm-timeslots',
        'synced_at': 1,
      });

      await migrateOfflineDatabase(db, 10, buildOfflineSchema());

      expect(await db.query('ref_cours'), isEmpty);
      expect(await db.query('ref_cours_notation'), isEmpty);
      expect(await db.query('evaluation'), isEmpty);
      expect(await db.query('note_evaluation'), isEmpty);
      expect(await db.query('ref_recurring_sessions'), isEmpty);
      expect(
        await db.query(
          'sync_meta',
          where: 'resource IN (?, ?, ?)',
          whereArgs: [
            'academics_cours',
            'academics_evaluations:co-other-teacher',
            'schedule_sessions',
          ],
        ),
        isEmpty,
      );
      expect(
        await db.query(
          'outbox',
          where: "aggregate_type = 'ACADEMICS_EVALUATION'",
        ),
        isEmpty,
      );

      // Rien d'autre n'est touché.
      final otherOutbox = await db.query(
        'outbox',
        where: "aggregate_type = 'PAYMENT'",
      );
      expect(otherOutbox.length, 1);
      final otherSyncMeta = await db.query(
        'sync_meta',
        where: 'resource = ?',
        whereArgs: ['schedule_time_slots'],
      );
      expect(otherSyncMeta.length, 1);
    },
  );

  test('v10→v11 : idempotent au rejeu', () async {
    final db = await _openV10Db();
    addTearDown(db.close);
    await migrateOfflineDatabase(db, 7, buildOfflineSchema());

    await migrateOfflineDatabase(db, 10, buildOfflineSchema());
    await migrateOfflineDatabase(
      db,
      10,
      buildOfflineSchema(),
    ); // ne doit pas lever

    expect(await db.query('ref_cours'), isEmpty);
  });

  test(
    'base pré-v8 (pas encore de Notes/Cours) : la purge est un no-op propre',
    () async {
      final db = await _openV10Db();
      addTearDown(db.close);

      // Migration depuis v7 (avant Notes/Cours) : les tables sont créées par
      // l'étape v8 puis immédiatement purgées par v11 (vides de toute façon)
      // dans le MÊME appel — ne doit pas lever.
      await migrateOfflineDatabase(db, 7, buildOfflineSchema());

      expect(await db.query('ref_cours'), isEmpty);
    },
  );
}
