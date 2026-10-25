import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v69 — le barème élargi (Q8) : colonnes nullables, `NULL` = pas
/// encore servi.
void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute(
      'CREATE TABLE ref_payroll_settings (school_id TEXT PRIMARY KEY, '
      'monthly_hours_divisor INTEGER NOT NULL)',
    );
    await db.insert('ref_payroll_settings', {
      'school_id': 'E1',
      'monthly_hours_divisor': 173,
    });
  });
  tearDown(() => db.close());

  test('une école déjà réglée garde ses valeurs, le barème élargi est NULL '
      '(pas encore servi)', () async {
    await migrateTenantDatabase(db, 68, newVersion: 69);
    await migrateTenantDatabase(db, 68, newVersion: 69);

    final row = (await db.query('ref_payroll_settings')).single;
    expect(row['monthly_hours_divisor'], 173);
    expect(row.containsKey('childcare_enabled'), isTrue);
    expect(row['childcare_enabled'], isNull);
    expect(row['loan_max_months'], isNull);
    expect(row.containsKey('signature_cashier_label'), isTrue);
  });
}
