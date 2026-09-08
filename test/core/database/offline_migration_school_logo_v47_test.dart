import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v47 — le logo de l'école.
///
/// Deux gestes, et leur séparation EST la décision : les empreintes rejoignent
/// `ref_school`, les octets vont dans `school_logo_cache`. `ref_school` est
/// purgée puis réinsérée à chaque pull référentiel ; y ranger des octets les
/// ferait retélécharger à chaque cycle, alors qu'une empreinte de 64 caractères
/// s'y réécrit pour rien.
///
/// ⚠️ **v47 est PRISE, pas réservée.** Le lot 2 du plan multi-école visait ce
/// numéro ; l'arbitrage a mis le logo devant, et le multi-école renumérotera en
/// v48. C'est la discipline que le v24 brûlé impose — un palier se prend en
/// fusionnant, jamais en s'annonçant.
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

  /// `ref_school` telle qu'elle existait AVANT la v47 : l'identité de l'école,
  /// sans aucune empreinte de logo.
  Future<void> createLegacyRefSchool() async {
    await db.execute('''
      CREATE TABLE ref_school (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        country TEXT,
        city TEXT,
        district TEXT,
        municipality TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        synced_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> seedSchool() => db.insert('ref_school', {
    'id': 'ecole-1',
    'name': 'COLLEGE LA FONTAINE',
    'municipality': 'Ngaliema',
    'city': 'Kinshasa',
    'address': '12, avenue de la Liberation',
    'phone': '+243900000000',
    'email': 'secretariat@lafontaine.cd',
    'synced_at': 0,
  });

  Future<Set<String>> columnNamesOf(String table) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return {for (final column in columns) column['name'] as String};
  }

  Future<void> migrateFrom(int oldVersion) =>
      migrateOfflineDatabase(db, oldVersion, buildOfflineSchema());

  test('ajoute les deux empreintes sans toucher à l\'école existante', () async {
    await createLegacyRefSchool();
    await seedSchool();

    await migrateFrom(46);

    expect(
      columnNamesOf('ref_school'),
      completion(containsAll(['logo_thermal_sha256', 'logo_display_sha256'])),
    );

    // Aucun backfill : `NULL` vaut « cette école n'a pas de logo », ce qui est
    // vrai de tout le parc jusqu'au premier pull qui en descend une. Et le
    // reste de l'identité doit être intact — la migration n'est pas un pull.
    final rows = await db.query('ref_school');
    expect(rows, hasLength(1));
    expect(rows.single['name'], 'COLLEGE LA FONTAINE');
    expect(rows.single['logo_thermal_sha256'], isNull);
    expect(rows.single['logo_display_sha256'], isNull);
  });

  test('crée la table des octets', () async {
    await createLegacyRefSchool();
    await migrateFrom(46);

    expect(
      columnNamesOf('school_logo_cache'),
      completion(
        containsAll(['school_id', 'variant', 'sha256', 'bytes', 'fetched_at']),
      ),
    );
  });

  /// Les octets font l'aller-retour tels quels. Un `BLOB` qui reviendrait
  /// tronqué ou ré-encodé rendrait la comparaison d'empreinte fausse au
  /// prochain démarrage, et le logo se retélécharger­ait en boucle sans que rien
  /// ne le signale.
  test('les octets se posent et se relisent à l\'identique', () async {
    await createLegacyRefSchool();
    await migrateFrom(46);

    final bytes = Uint8List.fromList(List<int>.generate(512, (i) => i % 256));
    await db.insert('school_logo_cache', {
      'school_id': 'ecole-1',
      'variant': 'thermal',
      'sha256': 'a' * 64,
      'bytes': bytes,
      'fetched_at': 1786500000000,
    });

    final rows = await db.query(
      'school_logo_cache',
      columns: const ['bytes'],
      where: 'school_id = ? AND variant = ?',
      whereArgs: ['ecole-1', 'thermal'],
    );
    expect(rows.single['bytes'], equals(bytes));
  });

  /// La contrainte est DOUBLÉE en SQL, comme celle de `editique_cache_entries` :
  /// c'est un invariant de stockage, pas une politique d'appelant. Une
  /// troisième variante existe côté serveur — `print`, aplatie sur blanc pour
  /// les documents — et elle n'a rien à faire sur une tablette.
  test('le CHECK refuse une variante inconnue', () async {
    await createLegacyRefSchool();
    await migrateFrom(46);

    expect(
      db.insert('school_logo_cache', {
        'school_id': 'ecole-1',
        'variant': 'print',
        'sha256': 'b' * 64,
        'bytes': Uint8List.fromList(const [1, 2, 3]),
        'fetched_at': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  /// La clé composite rend le doublon impossible par construction : il n'y a
  /// pas d'autre identité qu'(école, variante), et un id de synthèse aurait
  /// laissé deux lignes coexister pour le même logo.
  test('la clé (école, variante) refuse le doublon', () async {
    await createLegacyRefSchool();
    await migrateFrom(46);

    Future<void> put(String sha) => db.insert('school_logo_cache', {
      'school_id': 'ecole-1',
      'variant': 'display',
      'sha256': sha,
      'bytes': Uint8List.fromList(const [1]),
      'fetched_at': 0,
    });

    await put('c' * 64);
    expect(put('d' * 64), throwsA(isA<DatabaseException>()));
  });

  /// Deux écoles gardent chacune leur logo — c'est ce qui fait de cette table
  /// une table TENANT, et ce qui évite qu'un changement d'école sur la tablette
  /// serve le sceau de la précédente.
  test('deux écoles cohabitent sans se mélanger', () async {
    await createLegacyRefSchool();
    await migrateFrom(46);

    for (final school in const ['ecole-1', 'ecole-2']) {
      await db.insert('school_logo_cache', {
        'school_id': school,
        'variant': 'thermal',
        'sha256': school,
        'bytes': Uint8List.fromList(const [7]),
        'fetched_at': 0,
      });
    }

    final rows = await db.query(
      'school_logo_cache',
      columns: const ['sha256'],
      where: 'school_id = ? AND variant = ?',
      whereArgs: ['ecole-2', 'thermal'],
    );
    expect(rows.single['sha256'], 'ecole-2');
  });

  /// Le palier doit pouvoir être rejoué : une base traverse plusieurs versions
  /// d'affilée, et certains paliers recréent des tables depuis le DDL canonique
  /// — lequel porte déjà les deux colonnes. Sans la garde `_hasColumn`,
  /// `duplicate column name` ferait échouer l'escalier entier.
  test('le palier v47 se rejoue sans lever', () async {
    await createLegacyRefSchool();
    await seedSchool();

    await migrateFrom(46);
    await migrateFrom(46);

    expect(
      columnNamesOf('ref_school'),
      completion(containsAll(['logo_thermal_sha256', 'logo_display_sha256'])),
    );
    expect(await db.query('ref_school'), hasLength(1));
  });

  /// Le palier s'exerce aussi sur des bases PARTIELLES — chaque test de palier
  /// ne crée que les tables qui le concernent. Sans la garde `_hasTable`, un
  /// `ALTER` sur une table absente ferait tomber l'escalier entier, donc tous
  /// les autres paliers.
  test('ne touche pas une base où ref_school n\'existe pas', () async {
    await migrateFrom(46);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = {for (final t in tables) t['name'] as String};
    expect(names, isNot(contains('ref_school')));
    // La table des octets, elle, naît quand même : elle ne dépend de rien.
    expect(names, contains('school_logo_cache'));
  });
}
