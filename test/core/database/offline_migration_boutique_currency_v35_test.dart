import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v35 — la devise descend sur la **ligne** de vente, et la vente
/// perd ses montants.
///
/// C'est l'article qui est tarifé dans une unité, donc la ligne : un panier peut
/// en mêler deux, et c'est un acte de caisse — une vente, un reçu.
///
/// La colonne de ligne est **backfillée depuis la vente** : ces lignes ont été
/// encaissées dans la devise que la vente portait, et c'est la seule vérité
/// disponible. Sans backfill, une caisse qui a déjà vendu se retrouverait avec
/// des lignes sans unité — et un reçu réimprimé ne saurait plus dire en quoi il
/// a été payé.
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

  /// Les deux tables telles qu'elles existaient à la v34.
  Future<void> createV34({String currency = 'CDF'}) async {
    await db.execute('''
      CREATE TABLE boutique_sales (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        academic_year_id TEXT NOT NULL,
        payer_first_name TEXT,
        payer_last_name TEXT NOT NULL,
        payer_middle_name TEXT,
        payer_phone_number TEXT,
        payer_name TEXT,
        collected_by_id TEXT,
        collected_by_name TEXT,
        total_in_cents INTEGER NOT NULL,
        currency TEXT NOT NULL,
        sold_at TEXT NOT NULL,
        receipt_document_id TEXT,
        receipt_number TEXT,
        device_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
        sync_error TEXT,
        synced_at INTEGER,
        server_updated_at TEXT,
        updated_at INTEGER NOT NULL DEFAULT 0,
        printed_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE boutique_sale_lines (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        article_id TEXT NOT NULL,
        article_label TEXT NOT NULL,
        article_code TEXT,
        beneficiary_student_id TEXT,
        beneficiary_name TEXT,
        school_level_id TEXT,
        size TEXT,
        quantity INTEGER NOT NULL,
        unit_price_in_cents INTEGER NOT NULL,
        line_total_in_cents INTEGER NOT NULL,
        catalog_price_in_cents INTEGER,
        position INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.insert('boutique_sales', {
      'id': 'v1',
      'school_id': 'E1',
      'academic_year_id': 'ay-1',
      'payer_last_name': 'Ndombo',
      'total_in_cents': 90000,
      'currency': currency,
      'sold_at': '2026-08-30T11:42:00Z',
      'updated_at': 0,
    });
    await db.insert('boutique_sale_lines', {
      'id': 'l1',
      'sale_id': 'v1',
      'article_id': 'art-1',
      'article_label': 'Manuel',
      'quantity': 1,
      'unit_price_in_cents': 90000,
      'line_total_in_cents': 90000,
      'position': 0,
    });
  }

  test('la ligne hérite de la devise de sa vente', () async {
    await createV34();

    await migrateFrom(34);

    final line = (await db.query('boutique_sale_lines')).single;
    expect(line['currency'], 'CDF');
  });

  test('la vente perd ses montants, la ligne les garde', () async {
    await createV34();

    await migrateFrom(34);

    final saleColumns = {
      for (final c in await db.rawQuery('PRAGMA table_info(boutique_sales)'))
        c['name'] as String,
    };
    expect(saleColumns, isNot(contains('total_in_cents')));
    expect(saleColumns, isNot(contains('currency')));

    final line = (await db.query('boutique_sale_lines')).single;
    expect(line['line_total_in_cents'], 90000);
  });

  test('la vente elle-même SURVIT — c\'est de l\'argent encaissé', () async {
    // Reconstruite avec copie, jamais vidée : perdre une ligne serait perdre
    // une vente que le reçu papier atteste déjà.
    await createV34();

    await migrateFrom(34);

    final sale = (await db.query('boutique_sales')).single;
    expect(sale['id'], 'v1');
    expect(sale['payer_last_name'], 'Ndombo');
    expect(sale['sold_at'], '2026-08-30T11:42:00Z');
  });

  test('le palier se rejoue sans rien détruire', () async {
    await createV34();
    await migrateFrom(34);

    await migrateFrom(34);

    expect(await db.query('boutique_sales'), hasLength(1));
    expect((await db.query('boutique_sale_lines')).single['currency'], 'CDF');
  });

  test('ne fait rien sur une base qui n\'a pas la caisse', () async {
    await expectLater(migrateFrom(34), completes);
  });
}
