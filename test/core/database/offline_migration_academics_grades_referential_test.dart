import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v11→v12 : bundle `grades-referential` (5 tables réf
/// neuves), colonnes `evaluation.chapitre_ids_json`/`rejection_code` et
/// `note_evaluation.rejection_reason`, et la purge du squelette
/// `ref_cours_notation` (workaround online v9, retiré au profit du bundle) +
/// son curseur `sync_meta` résiduel.
bool _ffiInitialized = false;

Future<Database> _openDb() async {
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
    'v11→v12 : nouvelles tables bundle + colonnes + purge du squelette',
    () async {
      final db = await _openDb();
      addTearDown(db.close);

      // Setup : rejoue tout le schéma jusqu'à v12 (idempotent, tables vides).
      await migrateOfflineDatabase(db, 7, buildOfflineSchema());

      // État « v11 » simulé : le squelette de notation porte encore des
      // données (workaround online), et son curseur sync_meta existe.
      await db.insert('ref_cours_notation', {
        'cours_id': 'co-1',
        'classroom_id': 'c1',
        'branche_nom': 'Maths',
        'effectif': 30,
        'periodes_json': '[]',
        'synced_at': 1,
      });
      await db.insert('sync_meta', {
        'resource': 'academics_cours_notation',
        'cursor': null,
        'synced_at': 1,
      });
      // Ressource sans rapport : ne doit pas être touchée.
      await db.insert('sync_meta', {
        'resource': 'academics_cours',
        'cursor': 'wm-1',
        'synced_at': 1,
      });
      await db.insert('evaluation', {
        'id': 'ev-1',
        'cours_id': 'co-1',
        'type': 'INTERRO',
        'eval_date': 1,
        'max_points': 20.0,
        'poids': 1,
        'updated_at': 1,
        'sync_status': 'SYNCED',
      });

      // Déclenche UNIQUEMENT l'étape v12 (oldVersion=11 < 12, mais pas < 8..11).
      await migrateOfflineDatabase(db, 11, buildOfflineSchema());

      // Squelette purgé (données + curseur), mais table conservée (inerte,
      // jamais droppée — idiome constant du migrateur).
      expect(await db.query('ref_cours_notation'), isEmpty);
      expect(
        await db.query(
          'sync_meta',
          where: 'resource = ?',
          whereArgs: ['academics_cours_notation'],
        ),
        isEmpty,
      );
      // Ressource sans rapport intacte.
      expect(
        await db.query(
          'sync_meta',
          where: 'resource = ?',
          whereArgs: ['academics_cours'],
        ),
        hasLength(1),
      );

      // `evaluation.chapitre_ids_json` défaut '[]' sur une ligne pré-migration
      // (insérée sans la colonne) ; `rejection_code` nullable.
      final evalRows = await db.query(
        'evaluation',
        where: 'id = ?',
        whereArgs: ['ev-1'],
      );
      expect(evalRows.single['chapitre_ids_json'], '[]');
      expect(evalRows.single['rejection_code'], isNull);

      // Les 5 tables du bundle sont utilisables.
      await db.insert('ref_branche', {'id': 'b1', 'nom': 'Mathématiques'});
      await db.insert('ref_ligne_bareme', {
        'id': 'lb-1',
        'grille_id': 'g1',
        'rubrique_id': 'r1',
        'branche_id': 'b1',
        'ordre': 1,
        'max_journalier_par_sous_periode': 2,
        'max_examen_par_periode_scolaire': null,
      });
      await db.insert('ref_chapitre', {
        'id': 'ch-1',
        'cours_id': 'co-1',
        'titre': 'Chapitre 1',
        'ordre': 1,
      });
      await db.insert('ref_periode', {
        'id': 'p-1',
        'academic_year_id': 'ay-1',
        'school_level_group_id': 'g-1',
        'ordre': 1,
        'statut': 'CLOTUREE',
      });
      await db.insert('ref_sous_periode', {
        'id': 'sp-1',
        'periode_scolaire_id': 'p-1',
        'ordre': 1,
        'statut': 'OUVERTE',
      });
      expect(await db.query('ref_branche'), hasLength(1));
      expect(
        (await db.query(
          'ref_ligne_bareme',
        )).single['max_examen_par_periode_scolaire'],
        isNull,
      );
      expect(await db.query('ref_chapitre'), hasLength(1));
      expect(await db.query('ref_periode'), hasLength(1));
      expect(await db.query('ref_sous_periode'), hasLength(1));

      // `note_evaluation.rejection_reason` insérable/nullable.
      await db.insert('note_evaluation', {
        'id': 'n-1',
        'evaluation_id': 'ev-1',
        'student_id': 's1',
        'points_obtenus': 12.0,
        'statut': 'NOTEE',
        'updated_at': 1,
        'sync_status': 'SYNC_ERROR',
        'rejection_reason': 'PERIODE_CLOSE',
      });
      final noteRows = await db.query('note_evaluation');
      expect(noteRows.single['rejection_reason'], 'PERIODE_CLOSE');
    },
  );

  test('v11→v12 : idempotent au rejeu', () async {
    final db = await _openDb();
    addTearDown(db.close);
    await migrateOfflineDatabase(db, 7, buildOfflineSchema());

    await migrateOfflineDatabase(db, 11, buildOfflineSchema());
    await migrateOfflineDatabase(db, 11, buildOfflineSchema()); // ne lève pas

    expect(await db.query('ref_cours_notation'), isEmpty);
  });
}
