import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v40 — `ref_exchange_rates`, le taux de guichet.
///
/// Ce que la table rend possible : écrire le nombre qui relie ce qui est PERÇU
/// (devise reçue) à ce qui est IMPUTÉ (devise de la créance), et le lire hors
/// ligne. C'est une table de **cache référentiel** : création pure, aucun
/// backfill — elle se remplit au pull et ne se rattrape pas.
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

  Future<bool> hasTable(String name) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [name],
    );
    return rows.isNotEmpty;
  }

  Future<Set<String>> columnNames() async {
    final columns = await db.rawQuery('PRAGMA table_info(ref_exchange_rates)');
    return {for (final column in columns) column['name'] as String};
  }

  Future<int> seedRate({
    String schoolId = 'school-1',
    String base = 'USD',
    String quote = 'CDF',
    String effectiveFrom = '2026-09-01T06:00:00Z',
    int rateMicros = 1666670000,
    int? bandBp = 200,
  }) => db.insert('ref_exchange_rates', {
    'school_id': schoolId,
    'base': base,
    'quote': quote,
    'effective_from': effectiveFrom,
    'rate_micros': rateMicros,
    'divergence_band_bp': bandBp,
    'set_by': 'directrice',
    'synced_at': 1756700000000,
  });

  test('crée la table sur une base qui monte de la v39', () async {
    expect(await hasTable('ref_exchange_rates'), isFalse);

    await migrateFrom(39);

    expect(await hasTable('ref_exchange_rates'), isTrue);
    expect(
      await columnNames(),
      containsAll(<String>[
        'school_id',
        'base',
        'quote',
        'effective_from',
        'rate_micros',
        'divergence_band_bp',
        'set_by',
        'synced_at',
      ]),
    );
  });

  test('la table arrive vide — aucun backfill, et il n’en faut pas', () async {
    // Un cache référentiel se remplit au pull. Tant qu'il est vide, le guichet
    // n'ouvre aucune saisie bi-devise : il PROPOSE un taux, il ne l'invente pas.
    await migrateFrom(39);
    expect(await db.query('ref_exchange_rates'), isEmpty);
  });

  test(
    'le taux se stocke en micro-unités entières, jamais en flottant',
    () async {
      await migrateFrom(39);
      await seedRate();

      final row = (await db.query('ref_exchange_rates')).single;
      expect(row['rate_micros'], 1666670000);
      expect(row['rate_micros'], isA<int>());
    },
  );

  test('la clé porte la date : une série, pas une valeur remplacée', () async {
    await migrateFrom(39);
    await seedRate(
      effectiveFrom: '2026-09-01T06:00:00Z',
      rateMicros: 2500000000,
    );
    await seedRate(
      effectiveFrom: '2026-09-01T12:00:00Z',
      rateMicros: 2600000000,
    );

    final rows = await db.query(
      'ref_exchange_rates',
      orderBy: 'effective_from',
    );
    expect(rows, hasLength(2));
    expect(rows.first['rate_micros'], 2500000000);
    expect(rows.last['rate_micros'], 2600000000);
  });

  test('deux écoles sur la même tablette ne partagent pas leur taux', () async {
    // Dix flux portent déjà un curseur non scopé sur cette base. Un taux d'une
    // école servi à la tablette d'une autre est un défaut d'argent.
    await migrateFrom(39);
    await seedRate(schoolId: 'school-1', rateMicros: 2500000000);
    await seedRate(schoolId: 'school-2', rateMicros: 2900000000);

    final rows = await db.query(
      'ref_exchange_rates',
      where: 'school_id = ?',
      whereArgs: ['school-2'],
    );
    expect(rows, hasLength(1));
    expect(rows.single['rate_micros'], 2900000000);
  });

  test('la même paire à la même date ne s’écrit qu’une fois', () async {
    await migrateFrom(39);
    await seedRate();

    await expectLater(
      seedRate(rateMicros: 9999999999),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('la bande de divergence peut manquer — « non communiquée »', () async {
    // `NULL` n'est pas zéro : zéro signalerait tout, le contrôle retombe sur le
    // défaut de l'appelant.
    await migrateFrom(39);
    await seedRate(bandBp: null);

    expect(
      (await db.query('ref_exchange_rates')).single['divergence_band_bp'],
      isNull,
    );
  });

  test('le palier est rejouable', () async {
    await migrateFrom(39);
    await seedRate();

    await migrateFrom(39);

    expect(await hasTable('ref_exchange_rates'), isTrue);
    expect(await db.query('ref_exchange_rates'), hasLength(1));
  });

  test('une base montant de la v38 traverse la v39 puis pose la v40', () async {
    // Deux paliers d'affilée : le chemin d'une tablette qui a sauté une
    // livraison. On ne part pas de plus bas ici — le palier v2 rejoue le schéma
    // d'AUJOURD'HUI sur une base vide, ce qu'aucune base réelle ne fait, et
    // l'escalier bute alors sur son propre `ALTER` de la v3.
    await migrateFrom(38);
    expect(await hasTable('ref_exchange_rates'), isTrue);
  });

  test('newVersion borne l’escalier : sans la v40, pas de table', () async {
    // Le palier est bien CE palier, et non une étape ultérieure qui le
    // satisferait par accident.
    await migrateOfflineDatabase(db, 39, buildOfflineSchema(), newVersion: 39);
    expect(await hasTable('ref_exchange_rates'), isFalse);
  });
}
