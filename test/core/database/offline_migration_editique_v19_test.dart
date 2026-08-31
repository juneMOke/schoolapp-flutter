import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Migration v18→v19 — éditique offline (ADR-012 D-3).
///
/// Le reçu provisoire est une PROJECTION de lignes locales : ces lignes doivent
/// porter le caissier, l'appareil, et garder la trace du numéro provisoire que
/// le scellement écrase.
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

Future<List<String>> _columns(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((r) => r['name'] as String).toList();
}

/// Base au format v18 : `payments` et `generated_documents` sans les colonnes
/// de la v19.
Future<void> _seedLegacySchema(Database db) async {
  await db.execute('''
    CREATE TABLE payments (
      id TEXT PRIMARY KEY,
      client_uuid TEXT NOT NULL,
      student_id TEXT NOT NULL,
      amount_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL,
      paid_at TEXT NOT NULL,
      payer_first_name TEXT NOT NULL,
      payer_last_name TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE generated_documents (
      id TEXT PRIMARY KEY,
      doc_domain TEXT NOT NULL,
      payment_id TEXT,
      doc_type TEXT NOT NULL,
      number TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'PROVISIONAL',
      created_at INTEGER NOT NULL DEFAULT 0
    )
  ''');
}

void main() {
  test('v18→v19 : payments gagne caissier, appareil et receipt_id', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);
    await _seedLegacySchema(db);

    expect(await _columns(db, 'payments'), isNot(contains('cashier_uid')));

    await migrateOfflineDatabase(db, 18, buildOfflineSchema());

    expect(
      await _columns(db, 'payments'),
      containsAll(<String>[
        'cashier_uid',
        'cashier_first_name',
        'cashier_last_name',
        'device_id',
        'receipt_id',
      ]),
    );
  });

  test('v18→v19 : les colonnes neuves sont réellement écrivables', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);
    await _seedLegacySchema(db);

    await migrateOfflineDatabase(db, 18, buildOfflineSchema());

    await db.insert('payments', {
      'id': 'p-1',
      'client_uuid': 'p-1',
      'student_id': 's-1',
      'paid_at': '2026-08-04',
      'payer_first_name': 'Amina',
      'payer_last_name': 'Mbala',
      'cashier_uid': 'u-9',
      'cashier_first_name': 'Jean',
      'cashier_last_name': 'Kabeya',
      'device_id': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      'receipt_id': 'r-1',
    });

    final row = (await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: ['p-1'],
    )).single;
    expect(row['cashier_last_name'], 'Kabeya');
    expect(row['receipt_id'], 'r-1');
  });

  // Sans backfill, le scellement effacerait le lien vers le ticket papier déjà
  // remis au parent : `number` passe de `PROV-…` à `ETL-…` en place.
  test(
    'v18→v19 : le numéro provisoire des lignes en attente est recopié',
    () async {
      final db = await _openLegacyDb();
      addTearDown(db.close);
      await _seedLegacySchema(db);

      await db.insert('generated_documents', {
        'id': 'doc-prov',
        'doc_domain': 'PAYMENT',
        'payment_id': 'p-1',
        'doc_type': 'RC',
        'number': 'PROV-ABCD1234',
        'status': 'PROVISIONAL',
        'created_at': 1,
      });
      // Ligne déjà scellée : son numéro provisoire est perdu depuis longtemps,
      // rien à récupérer — et surtout, ne pas recopier le numéro DÉFINITIF dans
      // la colonne « provisoire », qui deviendrait un mensonge.
      await db.insert('generated_documents', {
        'id': 'doc-def',
        'doc_domain': 'PAYMENT',
        'payment_id': 'p-2',
        'doc_type': 'RC',
        'number': 'ETL-RC-2526-000212',
        'status': 'DEFINITIVE',
        'created_at': 2,
      });

      await migrateOfflineDatabase(db, 18, buildOfflineSchema());

      final prov = (await db.query(
        'generated_documents',
        where: 'id = ?',
        whereArgs: ['doc-prov'],
      )).single;
      final def = (await db.query(
        'generated_documents',
        where: 'id = ?',
        whereArgs: ['doc-def'],
      )).single;

      expect(prov['provisional_number'], 'PROV-ABCD1234');
      expect(def['provisional_number'], isNull);
    },
  );

  // Aucun `onDowngrade` n'existe : toute étape doit rester rejouable sans
  // lever ni détruire ce qu'elle a déjà écrit.
  test('v18→v19 : rejouable sans effet de bord', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);
    await _seedLegacySchema(db);
    await db.insert('generated_documents', {
      'id': 'doc-prov',
      'doc_domain': 'PAYMENT',
      'payment_id': 'p-1',
      'doc_type': 'RC',
      'number': 'PROV-ABCD1234',
      'status': 'PROVISIONAL',
      'created_at': 1,
    });

    await migrateOfflineDatabase(db, 18, buildOfflineSchema());
    await migrateOfflineDatabase(db, 18, buildOfflineSchema());

    final row = (await db.query(
      'generated_documents',
      where: 'id = ?',
      whereArgs: ['doc-prov'],
    )).single;
    expect(row['provisional_number'], 'PROV-ABCD1234');
    expect(await _columns(db, 'payments'), containsAll(<String>['device_id']));
  });

  // Une base antérieure aux tables Facturation ne doit pas faire échouer la
  // migration : les gardes `_hasTable` sautent l'étape.
  test('v18→v19 : sans les tables concernées, ne lève pas', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    await expectLater(
      migrateOfflineDatabase(db, 18, buildOfflineSchema()),
      completes,
    );
  });
}
