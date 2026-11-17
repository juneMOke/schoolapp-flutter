import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/schema/boutique_offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v81 — la date d'émission et l'URL du QR du reçu de vente, sur
/// `boutique_sales`. Deux colonnes nullables, aucune reprise : une vente
/// d'avant le palier imprime la date de la vente et sort sans QR.
void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
  });
  tearDown(() => db.close());

  Future<List<String>> columns() async => [
    for (final row in await db.rawQuery('PRAGMA table_info(boutique_sales)'))
      row['name'] as String,
  ];

  /// La table telle qu'avant le palier : la forme courante, moins les deux
  /// colonnes du palier.
  Future<void> createPreV81Sales() async {
    final sql = boutiqueOfflineTables
        .firstWhere((table) => table.name == 'boutique_sales')
        .createTableSql
        .replaceAll('receipt_emitted_on TEXT,', '')
        .replaceAll('receipt_verification_url TEXT,', '');
    await db.execute(sql);
    await db.insert('boutique_sales', {
      'id': 's-1',
      'school_id': 'E1',
      'academic_year_id': 'ay-1',
      'sold_at': '2026-11-17T08:00:00Z',
      'receipt_number': 'ETL-RV-2526-000001',
    });
  }

  test('les deux colonnes arrivent, nulles sur une vente existante', () async {
    await createPreV81Sales();
    expect(await columns(), isNot(contains('receipt_emitted_on')));

    await migrateTenantDatabase(db, 80, newVersion: 81);

    expect(
      await columns(),
      containsAll(['receipt_emitted_on', 'receipt_verification_url']),
    );
    final row = (await db.query('boutique_sales')).single;
    expect(row['receipt_number'], 'ETL-RV-2526-000001');
    expect(row['receipt_emitted_on'], isNull);
    expect(row['receipt_verification_url'], isNull);
  });

  test('rejouer le palier ne casse rien', () async {
    await createPreV81Sales();
    await migrateTenantDatabase(db, 80, newVersion: 81);
    await migrateTenantDatabase(db, 80, newVersion: 81);
    expect(await db.query('boutique_sales'), hasLength(1));
  });

  test('sans table boutique, le palier passe sans rien créer', () async {
    await migrateTenantDatabase(db, 80, newVersion: 81);
    expect(await columns(), isEmpty);
  });
}
