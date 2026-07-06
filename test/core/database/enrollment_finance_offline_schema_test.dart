import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/database/schema/enrollment_finance_offline_schema.dart';

import '../../features/offline_full_db.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await openFullOfflineDb();
  });

  tearDown(() async {
    await db.close();
  });

  Future<Set<String>> tableNames() async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    return rows.map((r) => r['name'] as String).toSet();
  }

  test('toutes les tables de la branche + le socle sont créées', () async {
    final names = await tableNames();
    // Socle
    expect(names, containsAll(['outbox', 'sync_meta']));
    // Branche A
    expect(
      names,
      containsAll([
        'students',
        'parents',
        'student_parent',
        'enrollments',
        'ref_fee_tariffs',
        'student_charges',
        'payments',
        'payment_allocations',
        'generated_documents',
      ]),
    );
  });

  test('la liste exportée contient exactement 9 tables', () {
    expect(enrollmentFinanceOfflineTables, hasLength(9));
  });

  test('index F2/FF1 présents (phone, sync_status, client_uuid…)', () async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    final indexes = rows.map((r) => r['name'] as String).toSet();
    expect(
      indexes,
      containsAll([
        'idx_students_phone',
        'idx_enrollments_sync_status',
        'idx_parents_phone',
        'idx_student_charges_student_fee',
        'idx_payments_client_uuid',
      ]),
    );
  });

  test('montants en INTEGER centimes : round-trip sans flottant', () async {
    await db.insert('ref_fee_tariffs', {
      'id': 't1',
      'fee_code': 'TUITION',
      'label': 'Scolarité',
      'amount_in_cents': 1500000,
      'currency': 'USD',
      'school_level_id': 'lvl-1',
    });
    final rows = await db.query(
      'ref_fee_tariffs',
      where: 'id = ?',
      whereArgs: ['t1'],
    );
    expect(rows.first['amount_in_cents'], isA<int>());
    expect(rows.first['amount_in_cents'], 1500000);
  });
}
