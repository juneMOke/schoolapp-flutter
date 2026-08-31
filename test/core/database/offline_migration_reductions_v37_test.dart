import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v36 → v37 : le barème de réductions repris sur la forme que le
/// serveur sert vraiment (ADR-021, livré côté back après l'écriture de la v36).
///
/// La v36 attendait deux sections à plat, chacune avec son `id`, et un taux
/// nommé `value`. Le contrat livré ne donne aucun id — un type est identifié
/// par son code dans son école, une ligne par sa rubrique dans son type — et
/// nomme le taux `percentage`.
///
/// Ce que ce test protège :
///
///  1. **La forme converge, d'où qu'on vienne.** Une base v36 est refaite ; une
///     base v35 est créée directement à la bonne forme et l'étape v37 n'a alors
///     rien à faire. Les deux chemins doivent donner exactement les mêmes
///     colonnes — c'est la seule garantie qu'un `INSERT` du pull ne lèvera pas
///     « no such column » sur une tablette plutôt qu'une autre.
///  2. **Le scope école survit à la refonte.** La clé primaire porte désormais
///     ce que l'index unique portait : sans elle, le pull d'une école
///     écraserait le barème de l'autre sur une tablette partagée.
///  3. **L'étape est rejouable.** Elle se garde sur la présence de la colonne
///     `id` — la signature de la v36 — et ne touche donc pas à une table déjà
///     refaite. Sans cette garde, chaque montée viderait le barème.
bool _ffiInitialized = false;

/// Forme v36, telle qu'elle a été écrite avant la livraison du back. Épinglée
/// ici en dur : c'est l'état d'où l'on part, il ne doit pas suivre le schéma
/// courant.
const _legacyTypesSql = '''
  CREATE TABLE ref_reduction_types (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL DEFAULT '',
    code TEXT NOT NULL,
    label TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 1,
    synced_at INTEGER NOT NULL DEFAULT 0
  )
''';

const _legacyLinesSql = '''
  CREATE TABLE ref_reduction_lines (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL DEFAULT '',
    reduction_code TEXT NOT NULL,
    fee_code TEXT NOT NULL,
    value REAL NOT NULL,
    synced_at INTEGER NOT NULL DEFAULT 0
  )
''';

const _rebuiltTables = ['ref_reduction_types', 'ref_reduction_lines'];

Future<Database> _openDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
}

/// Base v36 : tout le schéma courant, sauf les deux tables du barème qui sont
/// créées à leur forme d'alors.
Future<Database> _openV36Db() async {
  final db = await _openDb();
  for (final table in buildOfflineSchema()) {
    if (_rebuiltTables.contains(table.name)) continue;
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(indexSql);
    }
  }
  await db.execute(_legacyTypesSql);
  await db.execute(_legacyLinesSql);
  await db.execute(
    'CREATE UNIQUE INDEX idx_ref_reduction_types_school_code '
    'ON ref_reduction_types(school_id, code)',
  );
  await db.execute(
    'CREATE UNIQUE INDEX idx_ref_reduction_lines_school_code_fee '
    'ON ref_reduction_lines(school_id, reduction_code, fee_code)',
  );
  return db;
}

/// Base v35 : le barème n'existe pas encore du tout.
Future<Database> _openV35Db() async {
  final db = await _openDb();
  for (final table in buildOfflineSchema()) {
    if (_rebuiltTables.contains(table.name)) continue;
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(indexSql);
    }
  }
  return db;
}

Future<Set<String>> _columnsOf(Database db, String table) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  return {for (final row in info) row['name'] as String};
}

Future<void> _migrate(Database db, int from) =>
    migrateOfflineDatabase(db, from, buildOfflineSchema(), newVersion: 37);

void main() {
  test('v36 → v37 : les deux tables reprennent la forme du contrat', () async {
    final db = await _openV36Db();
    addTearDown(db.close);

    expect(await _columnsOf(db, 'ref_reduction_types'), contains('id'));
    expect(await _columnsOf(db, 'ref_reduction_lines'), contains('value'));

    await _migrate(db, 36);

    expect(await _columnsOf(db, 'ref_reduction_types'), {
      'school_id',
      'code',
      'label',
      'active',
      'synced_at',
    });
    expect(await _columnsOf(db, 'ref_reduction_lines'), {
      'school_id',
      'reduction_code',
      'fee_code',
      'percentage',
      'synced_at',
    });
  });

  test('le barème de la v36 est jeté, pas recopié', () async {
    final db = await _openV36Db();
    addTearDown(db.close);
    await db.insert('ref_reduction_types', {
      'id': 't1',
      'school_id': 'A',
      'code': 'STAFF_CHILD',
      'label': 'Enfant du personnel',
      'active': 1,
      'synced_at': 1,
    });

    await _migrate(db, 36);

    // Décision assumée : ce sont des tables de CACHE référentiel, réécrites en
    // entier au prochain pull du bundle. Le seul coût est un barème absent
    // jusque-là — et aucune base de terrain n'a jamais porté la v36.
    expect(await db.query('ref_reduction_types'), isEmpty);
  });

  test(
    'v35 → v37 : la bonne forme du premier coup, sans passer par `id`',
    () async {
      final db = await _openV35Db();
      addTearDown(db.close);

      await _migrate(db, 35);

      // La v36 crée les tables depuis le schéma COURANT : elles naissent déjà à
      // la forme du contrat, et l'étape v37 ne trouve alors rien à refaire.
      expect(
        await _columnsOf(db, 'ref_reduction_types'),
        isNot(contains('id')),
      );
      expect(
        await _columnsOf(db, 'ref_reduction_lines'),
        contains('percentage'),
      );
    },
  );

  test('rejouable : une table déjà refaite garde son barème', () async {
    final db = await _openV36Db();
    addTearDown(db.close);
    await _migrate(db, 36);
    await db.insert('ref_reduction_types', {
      'school_id': 'A',
      'code': 'STAFF_CHILD',
      'label': 'Enfant du personnel',
      'active': 1,
      'synced_at': 1,
    });

    // Sans la garde sur la colonne `id`, cette seconde montée reviderait la
    // table — et le guichet perdrait son barème à chaque démarrage.
    await _migrate(db, 36);

    expect(
      (await db.query('ref_reduction_types')).single['code'],
      'STAFF_CHILD',
    );
  });

  test('la clé naturelle survit à la refonte', () async {
    final db = await _openV36Db();
    addTearDown(db.close);
    await _migrate(db, 36);

    // Deux écoles, le même code : elles cohabitent. C'est `school_id` dans la
    // clé qui le permet — et sans lui, le pull de la seconde écraserait le
    // barème de la première sans que rien ne le signale.
    for (final schoolId in const ['A', 'B']) {
      await db.insert('ref_reduction_types', {
        'school_id': schoolId,
        'code': 'STAFF_CHILD',
        'label': 'Enfant du personnel',
        'active': 1,
        'synced_at': 0,
      });
      await db.insert('ref_reduction_lines', {
        'school_id': schoolId,
        'reduction_code': 'STAFF_CHILD',
        'fee_code': 'MINERVAL',
        'percentage': 50,
        'synced_at': 0,
      });
    }
    expect((await db.query('ref_reduction_types')).length, 2);
    expect((await db.query('ref_reduction_lines')).length, 2);

    await expectLater(
      db.insert('ref_reduction_types', {
        'school_id': 'A',
        'code': 'STAFF_CHILD',
        'label': 'Doublon',
        'active': 1,
        'synced_at': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      db.insert('ref_reduction_lines', {
        'school_id': 'A',
        'reduction_code': 'STAFF_CHILD',
        'fee_code': 'MINERVAL',
        'percentage': 10,
        'synced_at': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
