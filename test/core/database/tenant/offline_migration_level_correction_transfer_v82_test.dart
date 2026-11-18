import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/schema/enrollment_finance_offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v82 — `payment_allocations.level_correction_id`, la marque d'une
/// ligne de transfert. Colonne nullable, aucune reprise.
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
    for (final row in await db.rawQuery(
      'PRAGMA table_info(payment_allocations)',
    ))
      row['name'] as String,
  ];

  Future<void> createPreV82Allocations() async {
    final sql = paymentAllocationsTable.createTableSql.replaceAll(
      ',\n      level_correction_id TEXT',
      '',
    );
    expect(sql, isNot(contains('level_correction_id')));
    await db.execute(sql);
    await db.insert('payment_allocations', {
      'id': 'a-1',
      'client_uuid': 'a-1',
      'payment_id': 'p-1',
      'fee_code': 'TUITION',
      'student_charge_label': 'Minerval',
      'amount_in_cents': 5000,
      'currency': 'USD',
    });
  }

  test('la colonne arrive, nulle sur une imputation existante', () async {
    await createPreV82Allocations();

    await migrateTenantDatabase(db, 81, newVersion: 82);

    expect(await columns(), contains('level_correction_id'));
    final row = (await db.query('payment_allocations')).single;
    expect(row['amount_in_cents'], 5000);
    expect(row['level_correction_id'], isNull);
  });

  test('rejouer le palier ne casse rien', () async {
    await createPreV82Allocations();
    await migrateTenantDatabase(db, 81, newVersion: 82);
    await migrateTenantDatabase(db, 81, newVersion: 82);
    expect(await db.query('payment_allocations'), hasLength(1));
  });

  test(
    'le curseur des versements repart de zéro, les autres restent',
    () async {
      await createPreV82Allocations();
      await db.execute(
        'CREATE TABLE sync_meta (resource TEXT PRIMARY KEY, cursor TEXT, '
        'synced_at INTEGER)',
      );
      for (final r in [
        'finance_payments',
        'finance_payments@u-1',
        'finance_charges',
      ]) {
        await db.insert('sync_meta', {'resource': r, 'cursor': 'W'});
      }

      await migrateTenantDatabase(db, 81, newVersion: 82);

      expect((await db.query('sync_meta')).map((r) => r['resource']), [
        'finance_charges',
      ]);
    },
  );

  test('sans table, le palier passe sans rien créer', () async {
    await migrateTenantDatabase(db, 81, newVersion: 82);
    expect(await columns(), isEmpty);
  });
}
