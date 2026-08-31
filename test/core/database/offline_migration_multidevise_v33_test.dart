import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v33 — les arriérés N-1 quittent la ligne de l'élève pour une table
/// fille, une entrée **par devise**.
///
/// La colonne scalaire étiquetait la somme de tous les postes avec la devise du
/// premier : un élève devant 425,00 $ et 90 000 FC se voyait annoncer
/// « 90 425,00 $ ».
///
/// `ref_previous_year_students` est 100 % dérivée de la synchro — le seed la
/// remplace en bloc à chaque pull — donc elle se **recrée** plutôt que se
/// reconstruire par copie. Ce qui rend le rembobinage du curseur obligatoire :
/// sans lui, le prochain pull répondrait 304 et laisserait le guichet sans
/// vivier de réinscription jusqu'au rollover d'année.
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

  Future<void> migrateFrom(int oldVersion) =>
      migrateOfflineDatabase(db, oldVersion, buildOfflineSchema());

  /// La cohorte telle qu'elle existait à la v32, et le curseur qui la pilote.
  Future<void> createV32() async {
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
        medical_notes TEXT,
        synced_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_meta (
        resource TEXT PRIMARY KEY,
        cursor TEXT,
        synced_at INTEGER
      )
    ''');
    await db.insert('ref_previous_year_students', {
      'student_id': 'stu-N1',
      'matriculation_number': 'ETL-2025-0042',
      'first_name': 'Awa',
      'last_name': 'Kone',
      'gender': 'FEMALE',
      'date_of_birth': '2013-05-02',
      'previous_balance_in_cents': 250000,
      'currency': 'USD',
      'synced_at': 700,
    });
    await db.insert('sync_meta', {
      'resource': 'enrollment_reenrollment_cohort:ay-2026',
      'cursor': 'stu-N1',
      'synced_at': 700,
    });
  }

  test('la table perd ses colonnes de solde et gagne sa fille', () async {
    await createV32();

    await migrateFrom(32);

    final columns = await db.rawQuery(
      'PRAGMA table_info(ref_previous_year_students)',
    );
    final names = columns.map((c) => c['name'] as String).toSet();
    expect(names, isNot(contains('previous_balance_in_cents')));
    expect(names, isNot(contains('currency')));
    expect(names, contains('matriculation_number'));

    final child = await db.rawQuery(
      'PRAGMA table_info(ref_previous_year_student_balances)',
    );
    expect(
      child.map((c) => c['name'] as String).toSet(),
      containsAll(<String>['student_id', 'currency', 'amount_in_cents']),
    );
  });

  test(
    'le curseur de la cohorte est REMBOBINÉ, scope d\'année compris',
    () async {
      // Une purge sans rembobinage est pire que pas de purge : le serveur
      // répondrait 304 et la cohorte resterait vide jusqu'au rollover d'année.
      await createV32();

      await migrateFrom(32);

      expect(await db.query('sync_meta'), isEmpty);
    },
  );

  test('les curseurs des AUTRES ressources survivent', () async {
    await createV32();
    await db.insert('sync_meta', {
      'resource': 'finance_payments',
      'cursor': 'p-1',
      'synced_at': 700,
    });

    await migrateFrom(32);

    final rows = await db.query('sync_meta');
    expect(rows, hasLength(1));
    expect(rows.single['resource'], 'finance_payments');
  });

  test('le palier se rejoue sans redétruire une cohorte redescendue', () async {
    // Le piège d'un `DROP` inconditionnel : au second passage il emporterait
    // les lignes que le pull vient de réécrire. La garde se pose sur la FORME
    // RÉELLE de la table, pas sur un drapeau.
    await createV32();
    await migrateFrom(32);

    await db.insert('ref_previous_year_students', {
      'student_id': 'stu-repull',
      'matriculation_number': 'ETL-2026-0001',
      'first_name': 'Nouveau',
      'last_name': 'Roster',
      'gender': 'MALE',
      'date_of_birth': '2014-01-01',
      'synced_at': 900,
    });
    await db.insert('ref_previous_year_student_balances', {
      'student_id': 'stu-repull',
      'currency': 'CDF',
      'amount_in_cents': 9000000,
    });
    await db.insert('sync_meta', {
      'resource': 'enrollment_reenrollment_cohort:ay-2026',
      'cursor': 'stu-repull',
      'synced_at': 900,
    });

    await migrateFrom(32);

    expect(await db.query('ref_previous_year_students'), hasLength(1));
    expect(await db.query('ref_previous_year_student_balances'), hasLength(1));
    expect(await db.query('sync_meta'), hasLength(1));
  });

  test('ne fait rien sur une base qui n\'a pas la cohorte', () async {
    // Bases partielles des tests de palier : une migration qui suppose une
    // table voisine cesse de monter le jour où quelqu'un la retire.
    await migrateFrom(32);

    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name='ref_previous_year_students'",
      ),
      hasLength(1),
    );
  });

  test('sans sync_meta, le palier monte quand même', () async {
    await db.execute('''
      CREATE TABLE ref_previous_year_students (
        student_id TEXT PRIMARY KEY,
        matriculation_number TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        gender TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        previous_balance_in_cents INTEGER NOT NULL DEFAULT 0,
        currency TEXT,
        synced_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await expectLater(migrateFrom(32), completes);
  });
}
