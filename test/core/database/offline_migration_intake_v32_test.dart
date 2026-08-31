import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v32 — les quatre champs que le guichet saisit et que le dossier ne
/// savait pas porter : « ancien élève », fiche santé, fiche santé N-1 proposée à
/// la réinscription, et le tuteur à appeler en urgence.
///
/// Rien ici ne concerne le caractère facultatif du bloc « école précédente » :
/// ses colonnes sont nullables depuis toujours côté local — la contrainte
/// vivait dans l'écran, pas en base.
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

void main() {
  late Database db;

  setUp(() async => db = await _openLegacyDb());
  tearDown(() async => db.close());

  /// Les trois tables telles qu'elles existaient à la v31.
  Future<void> createV31Tables() async {
    await db.execute('''
      CREATE TABLE enrollments (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        enrollment_type TEXT NOT NULL,
        status TEXT NOT NULL,
        academic_year_id TEXT NOT NULL,
        school_level_id TEXT,
        school_level_group_id TEXT,
        enrollment_date TEXT NOT NULL,
        enrollment_code TEXT,
        source_ref TEXT,
        previous_school_name TEXT,
        previous_academic_year TEXT,
        previous_school_level_group TEXT,
        previous_school_level TEXT,
        previous_school_level_id TEXT,
        previous_rate REAL,
        previous_rank INTEGER,
        validated_previous_year INTEGER,
        transfer_reason TEXT,
        cancellation_reason TEXT,
        emit_document INTEGER NOT NULL DEFAULT 1,
        sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
        sync_error TEXT,
        synced_at INTEGER,
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE student_parent (
        student_id TEXT NOT NULL,
        parent_id TEXT NOT NULL,
        relationship_type TEXT NOT NULL DEFAULT 'OTHER',
        PRIMARY KEY (student_id, parent_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE ref_previous_year_students (
        student_id TEXT PRIMARY KEY,
        matriculation_number TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        surname TEXT,
        gender TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        birth_place TEXT,
        previous_academic_year_id TEXT,
        previous_school_level_id TEXT,
        previous_classroom_id TEXT,
        guardian_name TEXT,
        guardian_phone TEXT,
        previous_balance_in_cents INTEGER NOT NULL DEFAULT 0,
        currency TEXT,
        synced_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> seedEnrollment(String id, String type) =>
      db.insert('enrollments', {
        'id': id,
        'student_id': 'stu-$id',
        'enrollment_type': type,
        'status': 'COMPLETED',
        'academic_year_id': 'y-1',
        'enrollment_date': '2026-08-30',
        'updated_at': 0,
      });

  Future<Set<String>> columnNames(String table) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return {for (final column in columns) column['name'] as String};
  }

  Future<void> migrateFrom(int oldVersion) =>
      migrateOfflineDatabase(db, oldVersion, buildOfflineSchema());

  test('les quatre colonnes apparaissent sur les trois tables', () async {
    await createV31Tables();

    await migrateFrom(31);

    expect(
      await columnNames('enrollments'),
      containsAll(['former_student', 'medical_notes']),
    );
    expect(await columnNames('student_parent'), contains('emergency_contact'));
    expect(
      await columnNames('ref_previous_year_students'),
      contains('medical_notes'),
    );
  });

  /// Le backfill est le MÊME compromis assumé que V100 côté serveur : le type
  /// d'inscription est la seule information que l'existant porte. Ce n'est pas
  /// que les deux notions soient synonymes — elles divergent dès qu'une école
  /// démarre sur l'application — c'est qu'aucune déclaration de guichet n'a
  /// jamais été possible sur ces lignes.
  test('former_student est backfillé depuis le type d\'inscription', () async {
    await createV31Tables();
    await seedEnrollment('re-1', 'RE_ENROLLMENT');
    await seedEnrollment('new-1', 'NEW_ENROLLMENT');
    await seedEnrollment('pre-1', 'PRE_ENROLLMENT');

    await migrateFrom(31);

    Future<Object?> formerOf(String id) async {
      final rows = await db.query(
        'enrollments',
        columns: const ['former_student'],
        where: 'id = ?',
        whereArgs: [id],
      );
      return rows.single['former_student'];
    }

    expect(await formerOf('re-1'), 1);
    expect(await formerOf('new-1'), 0);
    expect(await formerOf('pre-1'), 0);
  });

  test('la fiche santé reste vide sur l\'existant, et s\'écrit', () async {
    await createV31Tables();
    await seedEnrollment('e-1', 'NEW_ENROLLMENT');

    await migrateFrom(31);

    final before = await db.query(
      'enrollments',
      columns: const ['medical_notes'],
      where: 'id = ?',
      whereArgs: ['e-1'],
    );
    expect(before.single['medical_notes'], isNull);

    await db.update(
      'enrollments',
      {'medical_notes': 'Allergie aux arachides.'},
      where: 'id = ?',
      whereArgs: ['e-1'],
    );
    final after = await db.query(
      'enrollments',
      columns: const ['medical_notes'],
      where: 'id = ?',
      whereArgs: ['e-1'],
    );
    expect(after.single['medical_notes'], 'Allergie aux arachides.');
  });

  /// L'invariant « au plus un contact d'urgence par élève » est tenu EN BASE,
  /// pas seulement dans le DAO : l'index est le filet d'une écriture qui aurait
  /// échappé au chemin démote-puis-promeut.
  test('un élève ne peut pas avoir deux contacts d\'urgence', () async {
    await createV31Tables();
    await migrateFrom(31);

    await db.insert('student_parent', {
      'student_id': 'stu-1',
      'parent_id': 'par-1',
      'relationship_type': 'MOTHER',
      'emergency_contact': 1,
    });

    await expectLater(
      db.insert('student_parent', {
        'student_id': 'stu-1',
        'parent_id': 'par-2',
        'relationship_type': 'FATHER',
        'emergency_contact': 1,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  /// Index PARTIEL, jamais contrainte unique : les tuteurs ordinaires restent
  /// en nombre quelconque, et un même adulte peut être le contact d'urgence de
  /// plusieurs enfants — c'est le couple (élève, tuteur) qui porte le drapeau.
  test('les tuteurs ordinaires restent en nombre quelconque', () async {
    await createV31Tables();
    await migrateFrom(31);

    for (final parentId in ['par-1', 'par-2', 'par-3']) {
      await db.insert('student_parent', {
        'student_id': 'stu-1',
        'parent_id': parentId,
        'relationship_type': 'OTHER',
      });
    }
    // Le même adulte, contact d'urgence de deux enfants différents.
    await db.insert('student_parent', {
      'student_id': 'stu-2',
      'parent_id': 'par-9',
      'relationship_type': 'MOTHER',
      'emergency_contact': 1,
    });
    await expectLater(
      db.insert('student_parent', {
        'student_id': 'stu-3',
        'parent_id': 'par-9',
        'relationship_type': 'MOTHER',
        'emergency_contact': 1,
      }),
      completes,
    );

    expect(await db.query('student_parent'), hasLength(5));
  });

  /// Une base traverse plusieurs versions d'affilée, et certains paliers
  /// recréent des tables depuis le DDL canonique — lequel porte déjà les
  /// colonnes. Sans les gardes `_hasColumn`, `duplicate column name` ferait
  /// échouer l'escalier entier.
  test('le palier v32 se rejoue sans lever', () async {
    await createV31Tables();
    await seedEnrollment('re-1', 'RE_ENROLLMENT');

    await migrateFrom(31);
    await expectLater(migrateFrom(31), completes);

    expect(await columnNames('enrollments'), contains('former_student'));
    expect(await db.query('enrollments'), hasLength(1));
  });

  /// Un rejeu ne doit pas re-backfiller : une déclaration de guichet qui
  /// contredit le type d'inscription — le cas de l'école qui démarre sur
  /// l'application — serait sinon écrasée à chaque montée de version.
  test('le rejeu ne réécrit pas une déclaration du guichet', () async {
    await createV31Tables();
    await seedEnrollment('new-1', 'NEW_ENROLLMENT');
    await migrateFrom(31);

    // Le guichet déclare un ancien élève entré en NEW_ENROLLMENT.
    await db.update(
      'enrollments',
      {'former_student': 1},
      where: 'id = ?',
      whereArgs: ['new-1'],
    );

    await migrateFrom(31);

    final rows = await db.query(
      'enrollments',
      columns: const ['former_student'],
      where: 'id = ?',
      whereArgs: ['new-1'],
    );
    expect(rows.single['former_student'], 1);
  });

  /// Le migrateur s'exerce aussi sur des bases PARTIELLES : un `ALTER` sur une
  /// table absente ferait échouer l'escalier entier, donc tous les autres
  /// paliers.
  test('ne touche pas une base où les tables n\'existent pas', () async {
    await db.execute('CREATE TABLE autre_chose (id TEXT PRIMARY KEY)');

    await expectLater(migrateFrom(31), completes);
  });

  /// Le palier v2 rejoue le schéma d'AUJOURD'HUI sur une base d'ALORS. Une
  /// table déjà présente y garde sa forme ancienne — et l'index partiel de la
  /// v32 filtre sur une colonne née trente paliers plus loin. Sans la garde
  /// « ne poser que les index des tables que ce palier vient de créer », toute
  /// base montant de v1 échouait ici, et avec elle l'escalier entier.
  test(
    'le palier v2 ne pose pas l\'index sur une student_parent préexistante',
    () async {
      await db.execute('''
        CREATE TABLE student_parent (
          student_id TEXT NOT NULL,
          parent_id TEXT NOT NULL,
          relationship_type TEXT NOT NULL DEFAULT 'OTHER',
          PRIMARY KEY (student_id, parent_id)
        )
      ''');

      await expectLater(
        migrateOfflineDatabase(db, 1, buildOfflineSchema(), newVersion: 2),
        completes,
      );

      // La table garde sa forme d'alors : c'est le palier v32 qui la fera
      // évoluer, et lui seul qui posera l'index.
      expect(
        await columnNames('student_parent'),
        isNot(contains('emergency_contact')),
      );
    },
  );

  test('une base neuve porte les colonnes sans migration', () async {
    final schema = buildOfflineSchema();
    final enrollments = schema.firstWhere((t) => t.name == 'enrollments');
    final studentParent = schema.firstWhere((t) => t.name == 'student_parent');
    final cohort = schema.firstWhere(
      (t) => t.name == 'ref_previous_year_students',
    );

    // Le DDL canonique doit rester d'accord avec la migration : sinon les
    // colonnes n'existeraient que sur les installations mises à jour, ou que
    // sur les neuves — deux parcs qui divergent en silence.
    expect(
      enrollments.createTableSql,
      contains('former_student INTEGER NOT NULL DEFAULT 0'),
    );
    expect(enrollments.createTableSql, contains('medical_notes TEXT'));
    expect(
      studentParent.createTableSql,
      contains('emergency_contact INTEGER NOT NULL DEFAULT 0'),
    );
    expect(
      studentParent.createIndexSql.join('\n'),
      contains('ux_emergency_contact_per_student'),
    );
    expect(cohort.createTableSql, contains('medical_notes TEXT'));
  });
}
