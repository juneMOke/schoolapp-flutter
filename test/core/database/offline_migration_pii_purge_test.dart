import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v26→v27 (ADR-015 F8) : effacement de la PII élève
/// dormante et suppression du squelette de notation.
///
/// Ce que ce palier protège vraiment : cesser d'ÉCRIRE `students.phone_number`
/// et `students.email` (fait dans les DAO au même commit) n'aurait allégé que le
/// flux futur. Chaque tablette déjà en service — et il y en a — aurait gardé
/// indéfiniment les numéros et adresses descendus jusqu'ici. Sans cette étape,
/// le lot ne réduit rien du parc réel.
///
/// L'étape est un `UPDATE`, jamais un `DROP COLUMN` : `students` est la source
/// de Facturation, du Contrôle des frais, de Documents et du ticket imprimé
/// (tout y arrive par `JOIN students`), et SQLite ne sait pas retirer une
/// colonne sans reconstruire la table. Les colonnes restent donc déclarées,
/// inertes — c'est exactement ce que ces tests figent.
bool _ffiInitialized = false;

/// Ouvre une base « v26 » : le socle minimal + `students` dans sa forme
/// d'époque, index téléphone compris.
///
/// La DDL est écrite en dur, jamais lue depuis `buildOfflineSchema()` : celui-ci
/// décrit l'état COURANT (sans l'index), et un test de migration qui suit le
/// schéma vivant cesse de tester la migration le jour où le schéma bouge.
Future<Database> _openV26Db() async {
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
  await db.execute('''
    CREATE TABLE students (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      surname TEXT,
      gender TEXT NOT NULL,
      date_of_birth TEXT NOT NULL,
      birth_place TEXT,
      nationality TEXT,
      city TEXT,
      district TEXT,
      municipality TEXT,
      neighborhood TEXT,
      address TEXT,
      phone_number TEXT,
      matriculation_number TEXT,
      email TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      synced_at INTEGER,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('CREATE INDEX idx_students_phone ON students(phone_number)');
  return db;
}

Future<Set<String>> _indexNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'index'",
  );
  return rows.map((r) => r['name'] as String).toSet();
}

Future<bool> _hasTable(Database db, String name) async => (await db.query(
  'sqlite_master',
  where: 'type = ? AND name = ?',
  whereArgs: ['table', name],
)).isNotEmpty;

void main() {
  test(
    'v26→v27 : téléphone et e-mail effacés, le reste du dossier intact',
    () async {
      final db = await _openV26Db();
      addTearDown(db.close);

      // Deux élèves déjà descendus par le pull hydratant, PII comprise.
      await db.insert('students', {
        'id': 's1',
        'first_name': 'Amina',
        'last_name': 'Moke',
        'gender': 'FEMALE',
        'date_of_birth': '2015-04-02',
        'city': 'Goma',
        'address': '12 av. des Volcans',
        'phone_number': '+243900111222',
        'matriculation_number': 'MAT-0001',
        'email': 'amina@school.cd',
        'sync_status': 'SYNCED',
        'updated_at': 100,
      });
      await db.insert('students', {
        'id': 's2',
        'first_name': 'Grace',
        'last_name': 'Ilunga',
        'gender': 'FEMALE',
        'date_of_birth': '2014-01-09',
        'phone_number': '+243900333444',
        'email': 'grace@school.cd',
        'sync_status': 'SYNCED',
        'updated_at': 100,
      });

      // ⚠️ Une écriture locale NON acquittée traverse aussi le palier. La règle
      // money-grade du dépôt — « une migration ne détruit jamais une saisie en
      // attente » — doit valoir ici comme ailleurs : ces deux lignes attendent
      // d'être poussées, et rien de ce qui les rend poussables ne doit bouger.
      await db.insert('students', {
        'id': 's-pending',
        'first_name': 'Kevin',
        'last_name': 'Mbala',
        'gender': 'MALE',
        'date_of_birth': '2016-11-11',
        'phone_number': '+243900555666',
        'email': 'kevin@school.cd',
        'sync_status': 'PENDING_SYNC',
        'updated_at': 300,
      });
      await db.insert('students', {
        'id': 's-error',
        'first_name': 'Sarah',
        'last_name': 'Ngoy',
        'gender': 'FEMALE',
        'date_of_birth': '2016-02-20',
        'phone_number': '+243900777888',
        'sync_error': 'CHAMP_INVALIDE',
        'sync_status': 'SYNC_ERROR',
        'updated_at': 400,
      });

      await migrateOfflineDatabase(db, 26, buildOfflineSchema());

      final rows = await db.query('students', orderBy: 'id');
      expect(rows, hasLength(4));
      for (final r in rows) {
        expect(r['phone_number'], isNull);
        expect(r['email'], isNull);
      }

      // ⚠️ Le reste du dossier survit intact. Une migration d'hygiène qui
      // emporterait l'identité de l'élève serait bien pire que la PII qu'elle
      // efface : ces lignes sont la source des `JOIN students` de Facturation,
      // du Contrôle des frais, de Documents et du ticket imprimé.
      final amina = rows.firstWhere((r) => r['id'] == 's1');
      expect(amina['first_name'], 'Amina');
      expect(amina['last_name'], 'Moke');
      expect(amina['date_of_birth'], '2015-04-02');
      expect(amina['city'], 'Goma');
      expect(amina['address'], '12 av. des Volcans');
      expect(amina['matriculation_number'], 'MAT-0001');
      expect(amina['sync_status'], 'SYNCED');
      expect(amina['updated_at'], 100);

      // Les lignes en attente gardent EXACTEMENT ce qui les rend poussables.
      // `sync_status` intact → pas d'écriture perdue ni de re-push parasite ;
      // `updated_at` intact → pas de décalage LWW qui ferait perdre l'arbitrage
      // à la tablette au prochain delta.
      final pending = rows.firstWhere((r) => r['id'] == 's-pending');
      expect(pending['sync_status'], 'PENDING_SYNC');
      expect(pending['updated_at'], 300);
      expect(pending['first_name'], 'Kevin');
      expect(pending['phone_number'], isNull);
      expect(pending['email'], isNull);
      final errored = rows.firstWhere((r) => r['id'] == 's-error');
      expect(errored['sync_status'], 'SYNC_ERROR');
      expect(errored['sync_error'], 'CHAMP_INVALIDE');
      expect(errored['updated_at'], 400);

      // L'index disparaît, mais PAS les colonnes : elles restent déclarées et
      // insérables — un `DROP COLUMN` imposerait de reconstruire la table.
      expect(await _indexNames(db), isNot(contains('idx_students_phone')));
      await db.insert('students', {
        'id': 's3',
        'first_name': 'Jonas',
        'last_name': 'Kabila',
        'gender': 'MALE',
        'date_of_birth': '2013-06-30',
        'phone_number': null,
        'email': null,
        'sync_status': 'DRAFT',
        'updated_at': 200,
      });
      expect(await db.query('students'), hasLength(5));
    },
  );

  test('v26→v27 : idempotent au rejeu', () async {
    final db = await _openV26Db();
    addTearDown(db.close);
    await db.insert('students', {
      'id': 's1',
      'first_name': 'Amina',
      'last_name': 'Moke',
      'gender': 'FEMALE',
      'date_of_birth': '2015-04-02',
      'phone_number': '+243900111222',
      'sync_status': 'SYNCED',
      'updated_at': 100,
    });

    await migrateOfflineDatabase(db, 26, buildOfflineSchema());
    // Le `DROP INDEX` est en `IF EXISTS` et l'`UPDATE` est déjà à NULL : le
    // second passage ne doit pas lever. Sans le `IF EXISTS`, une migration
    // interrompue puis reprise échouerait au redémarrage suivant.
    await migrateOfflineDatabase(db, 26, buildOfflineSchema());

    final row = (await db.query('students')).single;
    expect(row['phone_number'], isNull);
    expect(row['first_name'], 'Amina');
  });

  test(
    'v26→v27 : une base SANS table students traverse le palier sans lever',
    () async {
      // Cas réel : une tablette d'enseignant. Son plan de sync ne contient pas
      // Inscription, donc `students` peut n'avoir jamais été matérialisée. Une
      // étape qui ne se garderait pas sur la présence de la table empêcherait
      // sa base de monter en version — l'app ne démarrerait plus.
      if (!_ffiInitialized) {
        sqfliteFfiInit();
        _ffiInitialized = true;
      }
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(db.close);
      await db.execute('''
        CREATE TABLE sync_meta (
          resource TEXT PRIMARY KEY,
          cursor TEXT,
          synced_at INTEGER
        )
      ''');

      await migrateOfflineDatabase(db, 26, buildOfflineSchema());

      expect(await _hasTable(db, 'students'), isFalse);
    },
  );

  test(
    'v26→v27 : le squelette de notation est supprimé, pas seulement vidé',
    () async {
      final db = await _openV26Db();
      addTearDown(db.close);
      // Forme d'époque (v9→v26) : la table était créée sur toute base neuve alors
      // que plus rien ne l'alimentait depuis la v12.
      await db.execute('''
      CREATE TABLE ref_cours_notation (
        cours_id TEXT PRIMARY KEY,
        classroom_id TEXT,
        branche_nom TEXT,
        effectif INTEGER NOT NULL DEFAULT 0,
        periodes_json TEXT NOT NULL,
        server_updated_at INTEGER,
        synced_at INTEGER NOT NULL
      )
    ''');

      await migrateOfflineDatabase(db, 26, buildOfflineSchema());

      expect(await _hasTable(db, 'ref_cours_notation'), isFalse);
      // Rejeu : le `DROP TABLE` est en `IF EXISTS`.
      await migrateOfflineDatabase(db, 26, buildOfflineSchema());
    },
  );

  test(
    'base pré-v9 : le palier v9 crée le squelette sans lire le schéma courant',
    () async {
      // ⚠️ Régression la plus coûteuse de ce lot. L'étape v9 lisait la DDL du
      // squelette dans `buildOfflineSchema()` par `schema.firstWhere` — qui lève
      // un `StateError` dès que la table quitte le schéma, et elle vient d'en
      // sortir. Toute base antérieure à la v9 aurait cessé de monter : l'app ne
      // démarre plus, sur une table que le palier v27 supprime six lignes plus
      // loin. Le DDL est donc inliné dans l'étape, où il décrit le passé.
      final db = await _openV26Db();
      addTearDown(db.close);

      await migrateOfflineDatabase(db, 8, buildOfflineSchema());

      // Créée par la v9, puis supprimée par la v27 dans le même parcours.
      expect(await _hasTable(db, 'ref_cours_notation'), isFalse);
      // La preuve que le parcours est bien allé au bout : la PII est effacée.
      expect(await _indexNames(db), isNot(contains('idx_students_phone')));
    },
  );
}
