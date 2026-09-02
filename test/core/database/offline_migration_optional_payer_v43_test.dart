import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v43 — le payeur devient FACULTATIF, des deux côtés du guichet.
///
/// Contrepartie de la V114 serveur. Deux choses à prouver, et elles ne se
/// prouvent pas au même endroit :
///
///  1. **Le `NOT NULL` est parti.** Sans cela, un encaissement anonyme échoue à
///     l'INSERT — sur du cash déjà pris au guichet, ticket déjà imprimé.
///  2. **Les `''` hérités sont devenus `NULL`.** C'est la moitié utile : le pull
///     boutique repliait sur `''` pour satisfaire la contrainte, et une vente
///     anonyme se relisait donc comme une vente au nom VIDE — assez pour
///     imprimer un cadre « Payeur » creux, qui sur une pièce se lit comme une
///     mention effacée.
///
/// Et une troisième, tacite : **aucune donnée n'est perdue**. La reconstruction
/// recopie colonne pour colonne, et une tablette qui monte avec trois mois de
/// caisse doit les retrouver intacts.
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
        newVersion: newVersion ?? 43,
      );

  /// `payments` dans sa forme v42 : les deux noms y sont `NOT NULL`.
  Future<void> createLegacyPayments() => db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        client_uuid TEXT NOT NULL,
        student_id TEXT NOT NULL,
        academic_year_id TEXT,
        method TEXT NOT NULL DEFAULT 'CASH',
        paid_at TEXT NOT NULL,
        payer_first_name TEXT NOT NULL,
        payer_last_name TEXT NOT NULL,
        payer_middle_name TEXT,
        payer_phone_number TEXT,
        status TEXT,
        cashier_uid TEXT,
        cashier_first_name TEXT,
        cashier_last_name TEXT,
        collected_by_id TEXT,
        collected_by_name TEXT,
        device_id TEXT,
        receipt_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
        sync_error TEXT,
        synced_at INTEGER,
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

  /// `boutique_sales` dans sa forme v42 : `payer_last_name` y est `NOT NULL`.
  Future<void> createLegacySales() => db.execute('''
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
        sold_at TEXT NOT NULL,
        receipt_document_id TEXT,
        receipt_number TEXT,
        device_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
        sync_error TEXT,
        synced_at INTEGER,
        server_updated_at TEXT,
        updated_at INTEGER NOT NULL DEFAULT 0,
        ticket_printed_at INTEGER
      )
    ''');

  Future<bool> isNotNull(String table, String column) async {
    for (final info in await db.rawQuery('PRAGMA table_info($table)')) {
      if (info['name'] == column) return (info['notnull'] as int? ?? 0) == 1;
    }
    fail('colonne $table.$column introuvable');
  }

  group('v43 — la contrainte tombe', () {
    test('payments accepte un encaissement sans payeur nommé', () async {
      await createLegacyPayments();
      await migrateFrom(42);

      expect(await isNotNull('payments', 'payer_first_name'), isFalse);
      expect(await isNotNull('payments', 'payer_last_name'), isFalse);

      // Le geste que la v42 refusait : de l'argent pris sans demander son nom
      // à qui le donnait. Un échec ici arriverait sur du cash déjà encaissé.
      await db.insert('payments', {
        'id': 'pay-anonyme',
        'client_uuid': 'pay-anonyme',
        'student_id': 'stu-1',
        'paid_at': '2026-09-02T10:00:00',
        'updated_at': 1,
      });

      final row = (await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: ['pay-anonyme'],
      )).single;
      expect(row['payer_first_name'], isNull);
      expect(row['payer_last_name'], isNull);
    });

    test('boutique_sales accepte une vente anonyme', () async {
      await createLegacySales();
      await migrateFrom(42);

      expect(await isNotNull('boutique_sales', 'payer_last_name'), isFalse);

      await db.insert('boutique_sales', {
        'id': 'sale-anonyme',
        'school_id': 'sch-1',
        'academic_year_id': 'ay-1',
        'sold_at': '2026-09-02T10:00:00',
        'updated_at': 1,
      });

      final row = (await db.query(
        'boutique_sales',
        where: 'id = ?',
        whereArgs: ['sale-anonyme'],
      )).single;
      expect(row['payer_last_name'], isNull);
    });
  });

  group('v43 — les chaînes vides héritées deviennent NULL', () {
    test('une vente descendue du delta sans nom se relit anonyme', () async {
      await createLegacySales();
      // Ce que `boutique_sale_pull_dao` écrivait avant la v43 pour satisfaire le
      // `NOT NULL` : une vente ANONYME rangée sous un nom de longueur zéro.
      await db.insert('boutique_sales', {
        'id': 'sale-heritee',
        'school_id': 'sch-1',
        'academic_year_id': 'ay-1',
        'payer_last_name': '',
        'payer_first_name': '',
        'payer_name': '',
        'sold_at': '2026-09-01T09:00:00',
        'updated_at': 1,
      });

      await migrateFrom(42);

      final row = (await db.query(
        'boutique_sales',
        where: 'id = ?',
        whereArgs: ['sale-heritee'],
      )).single;
      // `null` et non `''` : c'est ce que le ticket lit pour escamoter son bloc
      // payeur au lieu d'imprimer un cadre creux.
      expect(row['payer_last_name'], isNull);
      expect(row['payer_first_name'], isNull);
      expect(row['payer_name'], isNull);
    });

    test('un nom réel n\'est jamais touché', () async {
      await createLegacySales();
      await db.insert('boutique_sales', {
        'id': 'sale-nommee',
        'school_id': 'sch-1',
        'academic_year_id': 'ay-1',
        'payer_last_name': 'Ndombo',
        'payer_middle_name': 'Lelo',
        'payer_first_name': 'Willy',
        'payer_phone_number': '+243810220145',
        'payer_name': 'NDOMBO Lelo Willy',
        'sold_at': '2026-09-01T09:00:00',
        'updated_at': 1,
      });

      await migrateFrom(42);

      final row = (await db.query(
        'boutique_sales',
        where: 'id = ?',
        whereArgs: ['sale-nommee'],
      )).single;
      expect(row['payer_last_name'], 'Ndombo');
      expect(row['payer_middle_name'], 'Lelo');
      expect(row['payer_first_name'], 'Willy');
      expect(row['payer_phone_number'], '+243810220145');
      expect(row['payer_name'], 'NDOMBO Lelo Willy');
    });

    test('un versement nommé traverse la reconstruction intact', () async {
      await createLegacyPayments();
      await db.insert('payments', {
        'id': 'pay-1',
        'client_uuid': 'uuid-1',
        'student_id': 'stu-1',
        'academic_year_id': 'ay-1',
        'paid_at': '2026-09-01T09:00:00',
        'payer_first_name': 'Willy',
        'payer_last_name': 'Ndombo',
        'payer_middle_name': 'Lelo',
        'payer_phone_number': '+243810220145',
        'cashier_uid': 'usr-9',
        'receipt_id': 'doc-7',
        'sync_status': 'SYNCED',
        'updated_at': 42,
      });

      await migrateFrom(42);

      final row = (await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: ['pay-1'],
      )).single;
      expect(row['payer_first_name'], 'Willy');
      expect(row['payer_last_name'], 'Ndombo');
      expect(row['payer_middle_name'], 'Lelo');
      expect(row['payer_phone_number'], '+243810220145');
      // Les colonnes SANS rapport avec le payeur doivent survivre elles aussi :
      // c'est toute la table qui est reconstruite, pas deux colonnes.
      expect(row['cashier_uid'], 'usr-9');
      expect(row['receipt_id'], 'doc-7');
      expect(row['sync_status'], 'SYNCED');
      expect(row['updated_at'], 42);
    });
  });

  test('le palier est rejouable sur une base déjà en v43', () async {
    await createLegacySales();
    await db.insert('boutique_sales', {
      'id': 'sale-1',
      'school_id': 'sch-1',
      'academic_year_id': 'ay-1',
      'payer_last_name': 'Ndombo',
      'sold_at': '2026-09-01T09:00:00',
      'updated_at': 1,
    });

    await migrateFrom(42);
    // Deuxième passage : la contrainte n'est plus là, il n'y a plus rien à
    // reconstruire — et la normalisation doit rester sans effet.
    await migrateFrom(42);

    final rows = await db.query('boutique_sales');
    expect(rows, hasLength(1));
    expect(rows.single['payer_last_name'], 'Ndombo');
    expect(await isNotNull('boutique_sales', 'payer_last_name'), isFalse);
  });
}
