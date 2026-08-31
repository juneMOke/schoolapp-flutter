import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v35 → v36 : le catalogue des réductions et la mémoire des octrois
/// (ADR-021 V1).
///
/// Création pure, sans backfill. Ce que ce test protège tient en deux points :
///
///  1. **Le scope école est gravé dans le schéma, pas seulement dans le DAO.**
///     Les deux tables de barème n'ont pas d'année — le barème descend à la
///     racine du bundle référentiel — donc `school_id` est la SEULE chose qui
///     empêche le pull d'une école d'écraser le barème de l'autre sur une
///     tablette partagée. L'index unique le rend impossible à contourner par
///     mégarde.
///  2. **Aucun montant ne bouge.** La V1 ne calcule rien : `student_charges`
///     doit ressortir de la migration exactement comme elle y est entrée. Le
///     jour où quelqu'un « anticipera » la V2 en ajoutant la colonne de brut,
///     ce test le dira.
bool _ffiInitialized = false;

const _newTables = [
  'ref_reduction_types',
  'ref_reduction_lines',
  'enrollment_reductions',
];

Future<Database> _openV35Db() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  // Base v35 : tout le schéma SAUF les trois tables des réductions.
  for (final table in buildOfflineSchema()) {
    if (_newTables.contains(table.name)) continue;
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(indexSql);
    }
  }
  return db;
}

Future<bool> _hasTable(Database db, String table) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [table],
  );
  return rows.isNotEmpty;
}

Future<Set<String>> _columnsOf(Database db, String table) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  return {for (final row in info) row['name'] as String};
}

Future<void> _migrate(Database db) =>
    migrateOfflineDatabase(db, 35, buildOfflineSchema(), newVersion: 36);

void main() {
  late Database db;

  setUp(() async => db = await _openV35Db());
  tearDown(() async => db.close());

  test('v35 → v36 crée les trois tables', () async {
    for (final name in _newTables) {
      expect(await _hasTable(db, name), isFalse, reason: '$name en v35');
    }

    await _migrate(db);

    for (final name in _newTables) {
      expect(await _hasTable(db, name), isTrue, reason: '$name en v36');
    }
  });

  test('l\'étape est idempotente et ne perd pas le barème déjà descendu', () async {
    await _migrate(db);
    await db.insert('ref_reduction_types', {
      'id': 't1',
      'school_id': 'A',
      'code': 'STAFF_CHILD',
      'label': 'Enfant du personnel',
      'active': 1,
      'synced_at': 1,
    });

    await _migrate(db);

    final rows = await db.query('ref_reduction_types');
    expect(rows.single['code'], 'STAFF_CHILD');
  });

  test('deux écoles gardent chacune son barème sous le même code', () async {
    await _migrate(db);

    // Le scope école n'est pas qu'une clause WHERE au pull : sans `school_id`
    // dans la clé, le barème de la seconde école écraserait celui de la
    // première — et rien ne masquerait la perte en « cette école n'a pas de
    // barème », faute d'un filtre d'année pour l'absorber.
    for (final schoolId in const ['A', 'B']) {
      await db.insert('ref_reduction_types', {
        'id': 'type-$schoolId',
        'school_id': schoolId,
        'code': 'STAFF_CHILD',
        'label': 'Enfant du personnel',
        'active': 1,
        'synced_at': 0,
      });
      await db.insert('ref_reduction_lines', {
        'id': 'line-$schoolId',
        'school_id': schoolId,
        'reduction_code': 'STAFF_CHILD',
        'fee_code': 'MINERVAL',
        'value': 50,
        'synced_at': 0,
      });
    }

    expect((await db.query('ref_reduction_types')).length, 2);
    expect((await db.query('ref_reduction_lines')).length, 2);
  });

  test('un même code deux fois dans une école est refusé', () async {
    await _migrate(db);
    await db.insert('ref_reduction_types', {
      'id': 't1',
      'school_id': 'A',
      'code': 'STAFF_CHILD',
      'label': 'Enfant du personnel',
      'active': 1,
      'synced_at': 0,
    });

    await expectLater(
      db.insert('ref_reduction_types', {
        'id': 't2',
        'school_id': 'A',
        'code': 'STAFF_CHILD',
        'label': 'Doublon',
        'active': 1,
        'synced_at': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('un octroi ne se pose qu\'une fois par inscription et par code', () async {
    await _migrate(db);
    await db.insert('enrollment_reductions', {
      'enrollment_id': 'e1',
      'reduction_code': 'STAFF_CHILD',
      'updated_at': 1,
    });

    await expectLater(
      db.insert('enrollment_reductions', {
        'enrollment_id': 'e1',
        'reduction_code': 'STAFF_CHILD',
        'updated_at': 2,
      }),
      throwsA(isA<DatabaseException>()),
    );
    // Une AUTRE réduction sur la même inscription reste possible : c'est bien
    // le couple qui est unique, pas l'inscription.
    await db.insert('enrollment_reductions', {
      'enrollment_id': 'e1',
      'reduction_code': 'SIBLING',
      'updated_at': 2,
    });
    expect((await db.query('enrollment_reductions')).length, 2);
  });

  test('aucun montant ne bouge : `student_charges` sort intacte', () async {
    final before = await _columnsOf(db, 'student_charges');

    await _migrate(db);

    expect(await _columnsOf(db, 'student_charges'), before);
    // La V1 est « mémoire seule ». Le jour où quelqu'un anticipe le calcul de
    // la V2 en posant la colonne de brut ici, c'est cette ligne qui le dira —
    // et le semis local, lui, doit rester au tarif plein.
    expect(before, isNot(contains('gross_amount_in_cents')));
    expect(before, isNot(contains('reduction_code')));
  });
}
