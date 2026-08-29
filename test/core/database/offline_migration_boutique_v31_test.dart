import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v30 → v31 : les quatre tables de la caisse boutique (ADR-020).
///
/// Création pure, sans backfill — le module n'existait pas. Ce que ce test
/// protège n'est pas la création elle-même (elle serait visible au premier
/// écran) mais **la forme des colonnes d'argent**, dont deux erreurs se
/// paieraient en silence : un `catalog_price_in_cents` rendu non nullable
/// obligerait à écrire zéro là où le catalogue ne dit plus rien, et une vente
/// sans `payer_last_name` partirait vers un 422 après encaissement.

const _boutiqueTables = [
  'ref_boutique_articles',
  'ref_boutique_article_level_prices',
  'boutique_sales',
  'boutique_sale_lines',
];

bool _ffiInitialized = false;

Future<Database> _openV30Db() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  // Base v30 : tout le schéma SAUF les tables de la boutique.
  for (final table in buildOfflineSchema()) {
    if (_boutiqueTables.contains(table.name)) continue;
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

Future<Map<String, Map<String, Object?>>> _columnsOf(
  Database db,
  String table,
) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return {for (final row in rows) row['name'] as String: row};
}

Future<void> _migrate(Database db) =>
    migrateOfflineDatabase(db, 30, buildOfflineSchema(), newVersion: 31);

void main() {
  late Database db;

  setUp(() async => db = await _openV30Db());
  tearDown(() async => db.close());

  test('v30 → v31 crée les quatre tables', () async {
    for (final table in _boutiqueTables) {
      expect(await _hasTable(db, table), isFalse, reason: table);
    }

    await _migrate(db);

    for (final table in _boutiqueTables) {
      expect(await _hasTable(db, table), isTrue, reason: table);
    }
  });

  test('l\'étape est idempotente au rejeu', () async {
    await _migrate(db);
    await _migrate(db);

    for (final table in _boutiqueTables) {
      expect(await _hasTable(db, table), isTrue, reason: table);
    }
  });

  test('une vente existante survit à un rejeu de migration', () async {
    await _migrate(db);
    await db.insert('boutique_sales', {
      'id': 'v1',
      'school_id': 'E1',
      'academic_year_id': 'A1',
      'payer_last_name': 'Ndombo',
      'total_in_cents': 3500,
      'currency': 'USD',
      'sold_at': '2026-08-29T11:42:00Z',
    });

    await _migrate(db);

    final rows = await db.query('boutique_sales');
    expect(rows.single['total_in_cents'], 3500);
  });

  group('la forme des colonnes d\'argent', () {
    setUp(() async => _migrate(db));

    test('`catalog_price_in_cents` accepte NULL', () async {
      // `null` dit « le catalogue ne disait plus rien » — grille rééditée,
      // devise changée, bénéficiaire réinscrit ailleurs. La colonne rendue
      // obligatoire forcerait à écrire zéro, qui se relit « il disait gratuit ».
      final columns = await _columnsOf(db, 'boutique_sale_lines');
      expect(columns['catalog_price_in_cents']!['notnull'], 0);

      await db.insert('boutique_sale_lines', {
        'id': 'l1',
        'sale_id': 'v1',
        'article_id': 'art1',
        'article_label': 'Polo Lacoste',
        'quantity': 1,
        'unit_price_in_cents': 1500,
        'line_total_in_cents': 1500,
      });

      final rows = await db.query('boutique_sale_lines');
      expect(rows.single['catalog_price_in_cents'], isNull);
    });

    test('`payer_last_name` est obligatoire, les deux autres non', () async {
      // Le serveur n'exige que le nom de famille (`@NotBlank` sur
      // `payerLastName`) : le laisser optionnel ici enverrait une vente
      // encaissée vers un refus, après que l'argent est passé au guichet.
      final columns = await _columnsOf(db, 'boutique_sales');
      expect(columns['payer_last_name']!['notnull'], 1);
      expect(columns['payer_first_name']!['notnull'], 0);
      expect(columns['payer_middle_name']!['notnull'], 0);
    });

    test('la vente ne porte aucune colonne de reste ni de solde', () async {
      // Comptant intégral (invariant I-5). Une colonne de reste, même toujours
      // à zéro, ferait croire qu'une vente boutique peut en avoir un — et le
      // premier écran qui la lirait construirait une créance qui n'existe pas.
      final columns = await _columnsOf(db, 'boutique_sales');
      expect(
        columns.keys.where(
          (name) =>
              name.contains('balance') ||
              name.contains('remaining') ||
              name.contains('paid') ||
              name.contains('due'),
        ),
        isEmpty,
      );
    });

    test('le catalogue porte `family` et `pricing_mode`, non nuls', () async {
      // `pricing_mode` est la SEULE source qui dise à la caisse s'il faut
      // demander un niveau (invariant I-1) ; `family` porte l'ordre
      // d'affichage, les groupes et les filtres. L'un ou l'autre nullable
      // rendrait le catalogue illisible sans qu'aucune requête n'échoue.
      final columns = await _columnsOf(db, 'ref_boutique_articles');
      expect(columns['pricing_mode']!['notnull'], 1);
      expect(columns['family']!['notnull'], 1);
    });

    test('une case de grille est unique par (article, niveau)', () async {
      // Deux lignes concurrentes rendraient la résolution de prix non
      // déterministe : la caisse retiendrait la première venue.
      await db.insert('ref_boutique_article_level_prices', {
        'article_id': 'art1',
        'school_level_id': 'n1',
        'price_in_cents': 1000,
      });

      expect(
        () => db.insert('ref_boutique_article_level_prices', {
          'article_id': 'art1',
          'school_level_id': 'n1',
          'price_in_cents': 1500,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
