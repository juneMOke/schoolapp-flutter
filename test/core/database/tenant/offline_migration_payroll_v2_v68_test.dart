import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v68 — la Paie v2 : réglages v2 et grade de l'agent, additifs.
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
    await db.execute(
      'CREATE TABLE staff_members (id TEXT PRIMARY KEY, last_name TEXT)',
    );
    await db.insert('ref_payroll_settings', {
      'school_id': 'E1',
      'monthly_hours_divisor': 173,
    });
  });
  tearDown(() => db.close());

  Future<Set<String>> columns(String table) async => {
    for (final row in await db.rawQuery('PRAGMA table_info($table)'))
      row['name'] as String,
  };

  test(
    'une école déjà réglée garde ses valeurs et prend les défauts v1',
    () async {
      await migrateTenantDatabase(db, 67, newVersion: 68);

      final row = (await db.query('ref_payroll_settings')).single;
      expect(row['monthly_hours_divisor'], 173);
      expect(row['work_days_divisor'], 26);
      expect(row['absence_deduction_enabled'], 0);
      expect(await columns('staff_members'), contains('grade'));
    },
  );

  test('rejouer le palier ne lève pas', () async {
    await migrateTenantDatabase(db, 67, newVersion: 68);
    await migrateTenantDatabase(db, 67, newVersion: 68);

    expect(
      await columns('ref_payroll_settings'),
      contains('work_days_divisor'),
    );
  });
}
