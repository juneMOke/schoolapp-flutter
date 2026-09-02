import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v45 — `parents.phone_number` perd son `NOT NULL`.
///
/// Contrepartie de la V117 serveur. Trois choses à prouver :
///
///  1. **La contrainte est partie.** Sans cela, un tuteur sans numéro échoue à
///     l'INSERT, et l'opérateur n'a d'autre issue que d'en inventer un.
///  2. **Les `''` hérités deviennent `NULL`.** Sur cette table c'est plus qu'une
///     question de propreté : le rapprochement compare des NUMÉROS, et une
///     valeur partagée ferait se reconnaître entre eux tous les tuteurs sans
///     numéro — la fusion que la V117 décrit comme le pire des cas.
///  3. **Rien n'est perdu.** Une tablette qui monte avec des mois de dossiers
///     doit les retrouver intacts, jusqu'aux colonnes sans rapport.
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

  Future<void> migrateFrom(int oldVersion, {int? newVersion}) =>
      migrateOfflineDatabase(
        db,
        oldVersion,
        buildOfflineSchema(),
        newVersion: newVersion ?? 45,
      );

  /// `parents` dans sa forme d'avant la v45 : le téléphone y est `NOT NULL`.
  Future<void> createLegacyParents() => db.execute('''
      CREATE TABLE parents (
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        surname TEXT,
        phone_number TEXT NOT NULL,
        email TEXT,
        identification_number TEXT,
        sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
        synced_at INTEGER,
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

  Future<bool> isNotNull(String table, String column) async {
    for (final info in await db.rawQuery('PRAGMA table_info($table)')) {
      if (info['name'] == column) return (info['notnull'] as int? ?? 0) == 1;
    }
    fail('colonne $table.$column introuvable');
  }

  test('la contrainte tombe : un tuteur sans numéro s\'enregistre', () async {
    await createLegacyParents();
    await migrateFrom(44);

    expect(await isNotNull('parents', 'phone_number'), isFalse);

    // Le geste que la contrainte refusait, et qui poussait à inventer un numéro.
    await db.insert('parents', {
      'id': 'par-sans-numero',
      'first_name': 'Willy',
      'last_name': 'Ndombo',
      'updated_at': 1,
    });

    final row = (await db.query(
      'parents',
      where: 'id = ?',
      whereArgs: ['par-sans-numero'],
    )).single;
    expect(row['phone_number'], isNull);
  });

  test('les chaînes vides héritées deviennent NULL', () async {
    await createLegacyParents();
    await db.insert('parents', {
      'id': 'par-vide',
      'first_name': 'Willy',
      'last_name': 'Ndombo',
      'phone_number': '',
      'updated_at': 1,
    });
    await db.insert('parents', {
      'id': 'par-blanc',
      'first_name': 'Jeanne',
      'last_name': 'Kabongo',
      'phone_number': '   ',
      'updated_at': 1,
    });

    await migrateFrom(44);

    for (final id in const ['par-vide', 'par-blanc']) {
      final row = (await db.query(
        'parents',
        where: 'id = ?',
        whereArgs: [id],
      )).single;
      expect(
        row['phone_number'],
        isNull,
        reason:
            '$id : une chaîne vide partagée ferait se reconnaître entre eux '
            'tous les tuteurs sans numéro',
      );
    }
  });

  test('un numéro réel traverse la reconstruction intact', () async {
    await createLegacyParents();
    await db.insert('parents', {
      'id': 'par-1',
      'first_name': 'Willy',
      'last_name': 'Ndombo',
      'surname': 'Lelo',
      'phone_number': '+243810220145',
      'email': 'w.ndombo@example.cd',
      'identification_number': 'PID-42',
      'sync_status': 'SYNCED',
      'synced_at': 99,
      'updated_at': 42,
    });

    await migrateFrom(44);

    final row = (await db.query(
      'parents',
      where: 'id = ?',
      whereArgs: ['par-1'],
    )).single;
    expect(row['phone_number'], '+243810220145');
    expect(row['surname'], 'Lelo');
    expect(row['email'], 'w.ndombo@example.cd');
    // Les colonnes sans rapport avec le téléphone doivent survivre elles aussi :
    // c'est toute la table qui est reconstruite, pas une colonne.
    expect(row['identification_number'], 'PID-42');
    expect(row['sync_status'], 'SYNCED');
    expect(row['synced_at'], 99);
    expect(row['updated_at'], 42);
  });

  test('les index de la table sont bien reposés', () async {
    await createLegacyParents();
    await migrateFrom(44);

    final indexes = {
      for (final row in await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND tbl_name = 'parents'",
      ))
        row['name'] as String,
    };
    // Une reconstruction qui oublie ses index laisse une table qui fonctionne
    // et qui rame — le genre de dette qu'aucun test fonctionnel ne rattrape.
    expect(indexes, containsAll(['idx_parents_phone', 'idx_parents_names']));
  });

  test('le palier est rejouable sur une base déjà en v45', () async {
    await createLegacyParents();
    await db.insert('parents', {
      'id': 'par-1',
      'first_name': 'Willy',
      'last_name': 'Ndombo',
      'phone_number': '+243810220145',
      'updated_at': 1,
    });

    await migrateFrom(44);
    // Deuxième passage : plus de contrainte à retirer, et la normalisation doit
    // rester sans effet.
    await migrateFrom(44);

    final rows = await db.query('parents');
    expect(rows, hasLength(1));
    expect(rows.single['phone_number'], '+243810220145');
    expect(await isNotNull('parents', 'phone_number'), isFalse);
  });
}
