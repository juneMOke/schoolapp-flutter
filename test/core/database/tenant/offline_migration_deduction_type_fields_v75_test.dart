import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/schema/payroll_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v75 — la fiche complète d'une rubrique. Une rubrique déjà rangée ne
/// retient rien tant que le socle ne l'a pas redescendue.
const String _typesV74 = '''
  CREATE TABLE payroll_deduction_types (
    school_id TEXT NOT NULL,
    id TEXT NOT NULL,
    label TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0,
    server_known INTEGER NOT NULL DEFAULT 0,
    acked_at INTEGER,
    client_updated_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'SYNCED',
    sync_error TEXT,
    sync_error_code TEXT,
    updated_at INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (school_id, id)
  )
''';

void main() {
  sqfliteFfiInit();

  late Database db;

  Future<Set<String>> columns(Database on) async => {
    for (final row in await on.rawQuery(
      'PRAGMA table_info(payroll_deduction_types)',
    ))
      row['name'] as String,
  };

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute(_typesV74);
  });

  tearDown(() => db.close());

  test('les colonnes naissent, sans rien retenir', () async {
    await db.insert('payroll_deduction_types', {
      'school_id': 's',
      'id': 't',
      'label': 'Cartes',
    });

    await migrateTenantDatabase(db, 74);

    final row = (await db.query('payroll_deduction_types')).single;
    expect(row['code'], '');
    expect(row['description'], isNull);
    expect(row['currency'], '');
    expect(row['default_amount_in_cents'], 0);
    expect(row['label'], 'Cartes');
  });

  test('le palier se rejoue sans dommage', () async {
    await migrateTenantDatabase(db, 74);
    await migrateTenantDatabase(db, 74);

    expect(await columns(db), contains('default_amount_in_cents'));
  });

  test('une base montée a les colonnes d\'une base neuve', () async {
    await migrateTenantDatabase(db, 74);
    final fresh = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    addTearDown(fresh.close);
    await fresh.execute(payrollDeductionTypesTable.createTableSql);

    expect(await columns(db), await columns(fresh));
  });
}
