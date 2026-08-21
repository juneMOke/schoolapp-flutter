import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';

import '../../offline_full_db.dart';

class _SeqIdGenerator extends IdGenerator {
  _SeqIdGenerator() : super(const Uuid());
  int _i = 0;
  @override
  String newId() => 'id-${_i++}';
}

void main() {
  late Database db;
  late FinanceLocalDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = FinanceLocalDao(db, _SeqIdGenerator());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertTariff(
    String id,
    String feeCode, {
    int amount = 100000,
    String? level = 'lvl-1',
    String? group,
    String? year = 'ay-1',
  }) => db.insert('ref_fee_tariffs', {
    'id': id,
    'fee_code': feeCode,
    'label': 'Libellé $feeCode',
    'amount_in_cents': amount,
    'currency': 'USD',
    'school_level_id': level,
    'school_level_group_id': group,
    'academic_year_id': year,
  });

  Future<void> insertCharge(
    String id,
    String studentId,
    String feeCode, {
    int expected = 100000,
    int paid = 0,
    String? year = 'ay-1',
  }) => db.insert('student_charges', {
    'id': id,
    'student_id': studentId,
    'fee_code': feeCode,
    'label': feeCode,
    'expected_amount_in_cents': expected,
    'amount_paid_in_cents': paid,
    'optimistic_paid_in_cents': 0,
    'currency': 'USD',
    'status': 'DUE',
    'sync_status': 'SYNCED',
    'academic_year_id': year,
  });

  Future<void> insertPaymentWithAllocation({
    required String paymentId,
    required String chargeId,
    required int amount,
    required String syncStatus,
  }) async {
    await db.insert('payments', {
      'id': paymentId,
      'client_uuid': paymentId,
      'student_id': 's1',
      'amount_in_cents': amount,
      'currency': 'USD',
      'method': 'CASH',
      'paid_at': '2026-08-14T10:00:00',
      'payer_first_name': 'Payeur',
      'payer_last_name': 'Test',
      'sync_status': syncStatus,
    });
    await db.insert('payment_allocations', {
      'id': 'alloc-$paymentId',
      'client_uuid': 'alloc-$paymentId',
      'payment_id': paymentId,
      'student_charge_id': chargeId,
      'fee_code': 'TUITION',
      'student_charge_label': 'TUITION',
      'amount_in_cents': amount,
      'currency': 'USD',
    });
  }

  group('getTariffsForLevel', () {
    test('retient le niveau visé et les tarifs de CYCLE seul', () async {
      await insertTariff('t-level', 'TUITION');
      await insertTariff('t-cycle', 'INSCRIPTION', level: null, group: 'grp-1');
      await insertTariff('t-other-level', 'CANTINE', level: 'lvl-2');

      final tariffs = await dao.getTariffsForLevel(
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        schoolLevelGroupId: 'grp-1',
      );

      expect(tariffs.map((t) => t.feeCode).toSet(), {'TUITION', 'INSCRIPTION'});
    });

    test('sans cycle fourni, seuls les tarifs du niveau exact', () async {
      await insertTariff('t-level', 'TUITION');
      await insertTariff('t-cycle', 'INSCRIPTION', level: null, group: 'grp-1');

      final tariffs = await dao.getTariffsForLevel(
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
      );

      expect(tariffs.map((t) => t.feeCode), ['TUITION']);
    });

    test('un tarif sans année vaut pour l\'année demandée', () async {
      await insertTariff('t-null-year', 'TUITION', year: null);
      await insertTariff('t-other-year', 'CANTINE', year: 'ay-2');

      final tariffs = await dao.getTariffsForLevel(
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
      );

      expect(tariffs.map((t) => t.feeCode), ['TUITION']);
    });
  });

  group('getFeeChargeAggregates', () {
    test('liste vide d\'élèves → aucune requête, aucun résultat', () async {
      await insertCharge('c1', 's1', 'TUITION');

      final rows = await dao.getFeeChargeAggregates(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
        studentIds: const [],
      );

      expect(rows, isEmpty);
    });

    test('ne remonte que les élèves demandés, sur le frais demandé', () async {
      await insertCharge('c1', 's1', 'TUITION');
      await insertCharge('c2', 's2', 'TUITION');
      await insertCharge('c3', 's1', 'CANTINE');

      final rows = await dao.getFeeChargeAggregates(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
        studentIds: const ['s1'],
      );

      expect(rows.length, 1);
      expect(rows.single.studentId, 's1');
      expect(rows.single.expectedInCents, 100000);
    });

    test('le payé COMPOSÉ additionne le miroir serveur et les paiements non '
        'remontés — PENDING_SYNC comme SYNC_ERROR', () async {
      await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 20000);
      await insertPaymentWithAllocation(
        paymentId: 'p-pending',
        chargeId: 'c1',
        amount: 30000,
        syncStatus: 'PENDING_SYNC',
      );
      await insertPaymentWithAllocation(
        paymentId: 'p-error',
        chargeId: 'c1',
        amount: 10000,
        syncStatus: 'SYNC_ERROR',
      );
      // Déjà remonté : compté par le miroir, jamais deux fois.
      await insertPaymentWithAllocation(
        paymentId: 'p-synced',
        chargeId: 'c1',
        amount: 5000,
        syncStatus: 'SYNCED',
      );

      final rows = await dao.getFeeChargeAggregates(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
        studentIds: const ['s1'],
      );

      final row = rows.single;
      expect(row.paidMirrorInCents, 20000);
      expect(row.paidPendingInCents, 40000);
      expect(row.paidTotalInCents, 60000);
      expect(row.remainingInCents, 40000);
    });

    test('le reste est borné à zéro sur un trop-perçu', () async {
      await insertCharge('c1', 's1', 'TUITION', expected: 50000, paid: 80000);

      final rows = await dao.getFeeChargeAggregates(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
        studentIds: const ['s1'],
      );

      expect(rows.single.remainingInCents, 0);
    });

    test('une créance sans année est rattachée à l\'année demandée', () async {
      await insertCharge('c1', 's1', 'TUITION', year: null);
      await insertCharge('c2', 's2', 'TUITION', year: 'ay-2');

      final rows = await dao.getFeeChargeAggregates(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
        studentIds: const ['s1', 's2'],
      );

      expect(rows.map((r) => r.studentId), ['s1']);
    });

    test(
      'deux créances du même frais sont sommées, pas tirées au sort',
      () async {
        await insertCharge('c1', 's1', 'TUITION', expected: 60000, paid: 10000);
        await insertCharge('c2', 's1', 'TUITION', expected: 40000, paid: 5000);

        final rows = await dao.getFeeChargeAggregates(
          academicYearId: 'ay-1',
          feeCode: 'TUITION',
          studentIds: const ['s1'],
        );

        expect(rows.length, 1);
        expect(rows.single.expectedInCents, 100000);
        expect(rows.single.paidMirrorInCents, 15000);
      },
    );

    test('découpe en lots au-delà de la limite de variables SQLite', () async {
      const total = 1200;
      final ids = <String>[];
      final batch = db.batch();
      for (var i = 0; i < total; i++) {
        final studentId = 'stu-$i';
        ids.add(studentId);
        batch.insert('student_charges', {
          'id': 'c-$i',
          'student_id': studentId,
          'fee_code': 'TUITION',
          'label': 'TUITION',
          'expected_amount_in_cents': 1000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'USD',
          'status': 'DUE',
          'sync_status': 'SYNCED',
          'academic_year_id': 'ay-1',
        });
      }
      await batch.commit(noResult: true);

      final rows = await dao.getFeeChargeAggregates(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
        studentIds: ids,
      );

      expect(rows.length, total);
      expect(rows.map((r) => r.studentId).toSet().length, total);
    });
  });
}
