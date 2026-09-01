import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/fee_tariff_local_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v39 — `ref_fee_tariffs.code`.
///
/// Ce que la colonne rend possible : **nommer** une tranche. Le serveur admet
/// depuis V94 plusieurs lignes de grille d'une même nature sur un niveau — un
/// minerval en sept tranches — et les départage par leur `code` (« T1 », « T2 »).
/// Le front recevait déjà ce champ dans le bundle référentiel et le jetait : au
/// guichet, sept créances s'affichaient sept fois « Minerval », et le reçu
/// imprimé disait la même chose.
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

  /// `ref_fee_tariffs` telle qu'elle existait AVANT la v39 : une ligne de grille
  /// n'y est nommée que par sa nature et son libellé.
  Future<void> createLegacyTariffs() async {
    await db.execute('''
      CREATE TABLE ref_fee_tariffs (
        id TEXT PRIMARY KEY,
        academic_year_id TEXT,
        school_level_id TEXT,
        school_level_group_id TEXT,
        fee_code TEXT NOT NULL,
        label TEXT NOT NULL,
        amount_in_cents INTEGER NOT NULL,
        currency TEXT NOT NULL,
        due_at TEXT,
        version INTEGER NOT NULL DEFAULT 0,
        synced_at INTEGER,
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> seedTariff(String id, String label) =>
      db.insert('ref_fee_tariffs', {
        'id': id,
        'academic_year_id': 'ay-1',
        'school_level_id': 'lvl-1',
        'school_level_group_id': 'grp-1',
        'fee_code': 'EXAMINATION',
        'label': label,
        'amount_in_cents': 500000,
        'currency': 'CDF',
        'due_at': '2027-02-28',
      });

  Future<Set<String>> columnNames() async {
    final columns = await db.rawQuery('PRAGMA table_info(ref_fee_tariffs)');
    return {for (final column in columns) column['name'] as String};
  }

  Future<void> migrateFrom(int oldVersion) =>
      migrateOfflineDatabase(db, oldVersion, buildOfflineSchema());

  test('ajoute le code sans toucher à la grille existante', () async {
    await createLegacyTariffs();
    await seedTariff('tar-1', 'Organisation matériel examens — 1/3');
    await seedTariff('tar-2', 'Organisation matériel examens — 2/3');

    await migrateFrom(38);

    expect(columnNames(), completion(contains('code')));

    // Aucun backfill, et c'est délibéré : `ref_fee_tariffs` est un CACHE
    // référentiel, il se jette et ne se rattrape pas. `replaceTariffsForYears`
    // réécrit chaque ligne des années du bundle au pull suivant. En attendant,
    // `NULL` se lit « on ne sait pas », et la désignation retombe sur le libellé
    // seul — c'est-à-dire sur le comportement d'avant ce palier.
    final rows = await db.query('ref_fee_tariffs', orderBy: 'id');
    expect(rows, hasLength(2));
    expect(rows.every((r) => r['code'] == null), isTrue);
    expect(rows.first['label'], 'Organisation matériel examens — 1/3');
    expect(rows.first['amount_in_cents'], 500000);
  });

  test('le code se pose, et se relit par le modèle', () async {
    await createLegacyTariffs();
    await seedTariff('tar-1', 'Organisation matériel examens — 2/3');
    await migrateFrom(38);

    await db.update(
      'ref_fee_tariffs',
      {'code': 'OM2'},
      where: 'id = ?',
      whereArgs: ['tar-1'],
    );

    final row = await db.query(
      'ref_fee_tariffs',
      where: 'id = ?',
      whereArgs: ['tar-1'],
    );
    final model = FeeTariffLocalModel.fromMap(row.single);
    expect(model.code, 'OM2');
    expect(model.toEntity().code, 'OM2');
  });

  /// Le modèle doit savoir relire une ligne d'avant le pull suivant : la colonne
  /// existe, elle est vide. Un `as String` la ferait lever, et c'est toute la
  /// grille qui deviendrait illisible — donc le semis des créances aussi.
  test('une ligne sans code se relit sans lever', () async {
    await createLegacyTariffs();
    await seedTariff('tar-1', 'Minerval');
    await migrateFrom(38);

    final row = await db.query('ref_fee_tariffs');
    final model = FeeTariffLocalModel.fromMap(row.single);
    expect(model.code, isNull);
    expect(model.toEntity().code, isNull);
  });

  /// Le palier doit pouvoir être rejoué : une base traverse plusieurs versions
  /// d'affilée, et certains paliers recréent des tables depuis le DDL canonique
  /// — lequel porte déjà la colonne. Sans la garde `_hasColumn`,
  /// `duplicate column name` ferait échouer l'escalier entier.
  test('le palier v39 se rejoue sans lever', () async {
    await createLegacyTariffs();
    await seedTariff('tar-1', 'Minerval');

    await migrateFrom(38);
    await expectLater(migrateFrom(38), completes);

    expect(columnNames(), completion(contains('code')));
    expect(await db.query('ref_fee_tariffs'), hasLength(1));
  });

  /// Le migrateur s'exerce aussi sur des bases PARTIELLES : chaque test de
  /// palier ne crée que les tables qui le concernent. Un `ALTER` sur une table
  /// absente ferait échouer l'escalier entier — donc tous les autres paliers.
  test('ne touche pas une base où ref_fee_tariffs n\'existe pas', () async {
    await db.execute('CREATE TABLE autre_chose (id TEXT PRIMARY KEY)');

    await expectLater(migrateFrom(38), completes);
  });

  test('une base neuve porte la colonne sans migration', () async {
    final tariffs = buildOfflineSchema().firstWhere(
      (table) => table.name == 'ref_fee_tariffs',
    );

    // Le DDL canonique doit rester d'accord avec la migration : sinon la
    // colonne n'existerait que sur les installations mises à jour, ou que sur
    // les neuves — deux parcs qui divergent en silence.
    expect(tariffs.createTableSql, contains('code TEXT'));
  });

  /// La grille est réécrite en entier par le pull (`ConflictAlgorithm.replace`
  /// sur `toMap()`). Le code doit donc figurer dans la carte écrite, sinon il
  /// serait posé par la migration puis effacé par la première synchronisation.
  test('le code part bien dans la carte écrite par le pull', () {
    const model = FeeTariffLocalModel(
      id: 'tar-1',
      academicYearId: 'ay-1',
      schoolLevelId: 'lvl-1',
      schoolLevelGroupId: 'grp-1',
      feeCode: 'EXAMINATION',
      code: 'OM2',
      label: 'Organisation matériel examens — 2/3',
      amountInCents: 500000,
      currency: 'CDF',
    );

    expect(model.toMap()['code'], 'OM2');
  });
}
