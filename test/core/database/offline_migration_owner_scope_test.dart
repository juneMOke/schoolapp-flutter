import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Migration v17→v18 — partition par compte des caches de référence cadrés
/// enseignant (`owner_uid`, cf. `core/offline/owner_scope.dart`).
///
/// La migration doit :
///  - ajouter `owner_uid` à `ref_recurring_sessions` / `ref_cours` ;
///  - RECRÉER les 5 tables du bundle `grades-referential` avec une clé primaire
///    composite `(id, owner_uid)` — sans elle, deux profs d'une même école
///    (mêmes ids de branches/barèmes) s'écraseraient mutuellement ;
///  - purger les lignes héritées ET leurs curseurs, ensemble. Purger les
///    données sans les curseurs est le pire des deux mondes : base vide et
///    prochain pull en `304`.
bool _ffiInitialized = false;

const _preV18Sessions = '''
  CREATE TABLE ref_recurring_sessions (
    id TEXT PRIMARY KEY,
    academic_year_id TEXT NOT NULL,
    cours_id TEXT NOT NULL,
    time_slot_id TEXT NOT NULL,
    day_of_week TEXT NOT NULL,
    room TEXT,
    teacher_id TEXT NOT NULL,
    classroom_id TEXT NOT NULL,
    teacher_label TEXT NOT NULL,
    classroom_label TEXT NOT NULL,
    subject_label TEXT NOT NULL,
    server_updated_at INTEGER,
    synced_at INTEGER NOT NULL
  )
''';

const _preV18Cours = '''
  CREATE TABLE ref_cours (
    id TEXT PRIMARY KEY,
    classroom_id TEXT NOT NULL,
    ligne_bareme_id TEXT NOT NULL,
    teacher_id TEXT,
    server_updated_at INTEGER,
    synced_at INTEGER NOT NULL
  )
''';

const _preV18Branche = '''
  CREATE TABLE ref_branche (
    id TEXT PRIMARY KEY,
    nom TEXT NOT NULL,
    code TEXT
  )
''';

const _preV18LigneBareme = '''
  CREATE TABLE ref_ligne_bareme (
    id TEXT PRIMARY KEY,
    grille_id TEXT NOT NULL,
    rubrique_id TEXT NOT NULL,
    branche_id TEXT NOT NULL,
    ordre INTEGER NOT NULL DEFAULT 0,
    max_journalier_par_sous_periode INTEGER NOT NULL,
    max_examen_par_periode_scolaire INTEGER
  )
''';

const _preV18Chapitre = '''
  CREATE TABLE ref_chapitre (
    id TEXT PRIMARY KEY,
    cours_id TEXT NOT NULL,
    titre TEXT NOT NULL,
    ordre INTEGER NOT NULL DEFAULT 0
  )
''';

const _preV18Periode = '''
  CREATE TABLE ref_periode (
    id TEXT PRIMARY KEY,
    academic_year_id TEXT NOT NULL,
    school_level_group_id TEXT NOT NULL,
    ordre INTEGER NOT NULL DEFAULT 0,
    statut TEXT NOT NULL,
    start_date TEXT,
    end_date TEXT
  )
''';

const _preV18SousPeriode = '''
  CREATE TABLE ref_sous_periode (
    id TEXT PRIMARY KEY,
    periode_scolaire_id TEXT NOT NULL,
    ordre INTEGER NOT NULL DEFAULT 0,
    statut TEXT NOT NULL,
    start_date TEXT,
    end_date TEXT
  )
''';

/// Base v17 réaliste : tables réf pré-partition, remplies, curseurs posés, plus
/// une outbox et une évaluation NON synchronisée (dont la migration ne doit
/// jamais s'approcher).
Future<Database> _openV17Db() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  for (final ddl in const [
    _preV18Sessions,
    _preV18Cours,
    _preV18Branche,
    _preV18LigneBareme,
    _preV18Chapitre,
    _preV18Periode,
    _preV18SousPeriode,
  ]) {
    await db.execute(ddl);
  }
  await db.execute('''
    CREATE TABLE sync_meta (
      resource TEXT PRIMARY KEY,
      cursor TEXT,
      synced_at INTEGER NOT NULL
    )
  ''');
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

  await db.insert('ref_recurring_sessions', {
    'id': 's-legacy',
    'academic_year_id': 'ay-1',
    'cours_id': 'co-1',
    'time_slot_id': 't1',
    'day_of_week': 'MON',
    'teacher_id': 'teacher-1',
    'classroom_id': 'class-1',
    'teacher_label': 'M. X',
    'classroom_label': '3e A',
    'subject_label': 'Maths',
    'synced_at': 1,
  });
  await db.insert('ref_cours', {
    'id': 'co-legacy',
    'classroom_id': 'class-1',
    'ligne_bareme_id': 'lb1',
    'synced_at': 1,
  });
  await db.insert('ref_branche', {'id': 'b1', 'nom': 'Maths'});
  for (final entry in const {
    'schedule_sessions': 'tok-sessions',
    'schedule_time_slots': 'tok-slots',
    'academics_cours': 'tok-cours',
    'academics_cours_bootstrap': 'DONE',
    'academics_grades_referential': '"etag"',
    'classrooms': 'tok-classes',
  }.entries) {
    await db.insert('sync_meta', {
      'resource': entry.key,
      'cursor': entry.value,
      'synced_at': 1,
    });
  }
  await db.insert('outbox', {
    'id': 'ob-1',
    'aggregate_type': 'EVALUATION',
    'aggregate_id': 'ev-1',
    'operation': 'CREATE',
    'payload': '{}',
    'created_at': 1,
  });
  return db;
}

Future<Set<String>> _columns(Database db, String table) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  return info.map((r) => r['name'] as String).toSet();
}

Future<String?> _cursor(Database db, String resource) async {
  final rows = await db.query(
    'sync_meta',
    where: 'resource = ?',
    whereArgs: [resource],
  );
  return rows.isEmpty ? null : rows.first['cursor'] as String?;
}

void main() {
  test(
    'v17→v18 : owner_uid ajouté aux tables réf cadrées enseignant',
    () async {
      final db = await _openV17Db();
      addTearDown(db.close);

      await migrateOfflineDatabase(db, 17, buildOfflineSchema());

      for (final table in const [
        'ref_recurring_sessions',
        'ref_cours',
        'ref_branche',
        'ref_ligne_bareme',
        'ref_chapitre',
        'ref_periode',
        'ref_sous_periode',
      ]) {
        expect(
          await _columns(db, table),
          contains('owner_uid'),
          reason: '$table doit porter owner_uid',
        );
      }
    },
  );

  test('v17→v18 : le bundle passe en clé primaire composite (id, owner_uid) — '
      'deux profs de la même école gardent chacun leur copie', () async {
    final db = await _openV17Db();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 17, buildOfflineSchema());

    // Même id de branche pour deux comptes : refusé avant, accepté après.
    await db.insert('ref_branche', {
      'id': 'b1',
      'owner_uid': 'uid-a',
      'nom': 'Maths (A)',
    });
    await db.insert('ref_branche', {
      'id': 'b1',
      'owner_uid': 'uid-b',
      'nom': 'Maths (B)',
    });

    final rows = await db.query('ref_branche', orderBy: 'owner_uid');
    expect(rows.map((r) => r['nom']), ['Maths (A)', 'Maths (B)']);
  });

  test('v17→v18 : les lignes héritées ET leurs curseurs sont purgés ensemble '
      '(sinon base vide + 304 éternel)', () async {
    final db = await _openV17Db();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 17, buildOfflineSchema());

    expect(await db.query('ref_recurring_sessions'), isEmpty);
    expect(await db.query('ref_cours'), isEmpty);
    expect(await db.query('ref_branche'), isEmpty);

    expect(await _cursor(db, 'schedule_sessions'), isNull);
    expect(await _cursor(db, 'academics_cours'), isNull);
    expect(await _cursor(db, 'academics_cours_bootstrap'), isNull);
    expect(await _cursor(db, 'academics_grades_referential'), isNull);
  });

  test('v17→v18 : les ressources NON repartitionnées gardent leur curseur '
      '(créneaux d\'école, classes)', () async {
    final db = await _openV17Db();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 17, buildOfflineSchema());

    expect(await _cursor(db, 'schedule_time_slots'), 'tok-slots');
    expect(await _cursor(db, 'classrooms'), 'tok-classes');
  });

  test('v17→v18 : l\'outbox n\'est jamais touchée', () async {
    final db = await _openV17Db();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 17, buildOfflineSchema());

    expect(await db.query('outbox'), hasLength(1));
  });

  test('v17→v18 : rejouable (idempotence du migrateur)', () async {
    final db = await _openV17Db();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 17, buildOfflineSchema());
    await migrateOfflineDatabase(db, 17, buildOfflineSchema());

    expect(await _columns(db, 'ref_cours'), contains('owner_uid'));
    expect(await db.query('ref_branche'), isEmpty);
  });
}
