import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_level_aggregate.dart';

import '../../offline_full_db.dart';

class _SeqIdGenerator extends IdGenerator {
  _SeqIdGenerator() : super(const Uuid());
  int _i = 0;
  @override
  String newId() => 'id-${_i++}';
}

/// Lectures du **tableau de bord** du Contrôle des frais (FCD-0) : la liste des
/// natures facturées, et la position de toute la population ventilée par
/// niveau.
///
/// Sur une vraie base sqflite en mémoire, jamais sur un faux DAO : ce qu'on
/// vérifie ici est du SQL — un `GROUP BY`, une sous-requête corrélée, une
/// clause conditionnelle — et un faux ne prouverait que la fidélité du faux.
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

  Future<void> insertCharge(
    String id,
    String studentId,
    String feeCode, {
    int expected = 100000,
    int paid = 0,
    String? year = 'ay-1',
    String? level = 'lvl-1',
    String? group = 'grp-1',
    String currency = 'USD',
  }) => db.insert('student_charges', {
    'id': id,
    'student_id': studentId,
    'fee_code': feeCode,
    'label': feeCode,
    'expected_amount_in_cents': expected,
    'amount_paid_in_cents': paid,
    'optimistic_paid_in_cents': 0,
    'currency': currency,
    'status': 'DUE',
    'sync_status': 'SYNCED',
    'academic_year_id': year,
    'school_level_id': level,
    'school_level_group_id': group,
  });

  Future<void> insertPaymentWithAllocation({
    required String paymentId,
    required String chargeId,
    required int amount,
    required String syncStatus,
    String currency = 'USD',
  }) async {
    await db.insert('payments', {
      'id': paymentId,
      'client_uuid': paymentId,
      'student_id': 's1',
      'method': 'CASH',
      'paid_at': '2026-09-02T10:00:00',
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
      'currency': currency,
    });
  }

  LocalFeeLevelAggregate pick(
    List<LocalFeeLevelAggregate> rows, {
    required String student,
    String? level,
  }) => rows.singleWhere(
    (r) => r.studentId == student && r.schoolLevelId == level,
  );

  group('getFeeCodesForYear', () {
    test('rend les natures FACTURÉES, la plus portée en tête — l\'écran ouvre '
        'sur la première', () async {
      await insertCharge('c1', 's1', 'TUITION');
      await insertCharge('c2', 's2', 'TUITION');
      await insertCharge('c3', 's1', 'CANTINE');

      // Alphabétiquement, CANTINE viendrait d'abord : ouvrir dessus poserait la
      // question du matin sur un frais marginal.
      expect(await dao.getFeeCodesForYear('ay-1'), ['TUITION', 'CANTINE']);
    });

    test('deux natures à égalité gardent un ordre STABLE', () async {
      await insertCharge('c1', 's1', 'TUITION');
      await insertCharge('c2', 's2', 'CANTINE');

      expect(await dao.getFeeCodesForYear('ay-1'), ['CANTINE', 'TUITION']);
      expect(await dao.getFeeCodesForYear('ay-1'), ['CANTINE', 'TUITION']);
    });

    test('une créance sans année vaut pour l\'année demandée ; celle d\'un '
        'autre exercice est écartée', () async {
      await insertCharge('c1', 's1', 'TUITION', year: null);
      await insertCharge('c2', 's2', 'CANTINE', year: 'ay-2');

      expect(await dao.getFeeCodesForYear('ay-1'), ['TUITION']);
    });

    test('aucune créance → liste vide, pas d\'erreur', () async {
      expect(await dao.getFeeCodesForYear('ay-1'), isEmpty);
    });
  });

  group('getFeeChargePositionsByLevel', () {
    test('découvre la population sans qu\'on la lui donne, sur le seul frais '
        'demandé', () async {
      await insertCharge('c1', 's1', 'TUITION');
      await insertCharge('c2', 's2', 'TUITION', level: 'lvl-2');
      await insertCharge('c3', 's3', 'CANTINE');

      final rows = await dao.getFeeChargePositionsByLevel(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
      );

      expect(rows.map((r) => r.studentId).toSet(), {'s1', 's2'});
      expect(pick(rows, student: 's2', level: 'lvl-2').schoolLevelId, 'lvl-2');
    });

    test(
      'le payé COMPOSÉ additionne le miroir et les paiements non remontés '
      '— PENDING_SYNC comme SYNC_ERROR, le SYNCED jamais deux fois',
      () async {
        await insertCharge(
          'c1',
          's1',
          'TUITION',
          expected: 100000,
          paid: 20000,
        );
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
        await insertPaymentWithAllocation(
          paymentId: 'p-synced',
          chargeId: 'c1',
          amount: 5000,
          syncStatus: 'SYNCED',
        );

        final position = pick(
          await dao.getFeeChargePositionsByLevel(
            academicYearId: 'ay-1',
            feeCode: 'TUITION',
          ),
          student: 's1',
          level: 'lvl-1',
        ).charge.positions.single;

        expect(position.paidMirrorInCents, 20000);
        expect(position.paidPendingInCents, 40000);
        expect(position.remainingInCents, 40000);
      },
    );

    test('un encaissement hors ligne suffit à SOLDER — sans lui, le taux du '
        'guichet resterait figé toute la matinée', () async {
      await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 0);
      await insertPaymentWithAllocation(
        paymentId: 'p-pending',
        chargeId: 'c1',
        amount: 100000,
        syncStatus: 'PENDING_SYNC',
      );

      final rows = await dao.getFeeChargePositionsByLevel(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
      );

      expect(rows.single.status, StudentChargeStatus.paid);
    });

    test(
      'multi-devise : soldé en USD mais débiteur en CDF n\'est PAS en ordre',
      () async {
        await insertCharge(
          'c-usd',
          's1',
          'TUITION',
          expected: 50000,
          paid: 50000,
        );
        await insertCharge(
          'c-cdf',
          's1',
          'TUITION',
          expected: 300000,
          paid: 0,
          currency: 'CDF',
        );

        final row = pick(
          await dao.getFeeChargePositionsByLevel(
            academicYearId: 'ay-1',
            feeCode: 'TUITION',
          ),
          student: 's1',
          level: 'lvl-1',
        );

        expect(row.charge.positions.map((p) => p.currency), ['CDF', 'USD']);
        expect(row.status, StudentChargeStatus.partial);
      },
    );

    test('un élève à cheval sur DEUX niveaux compte dans les deux — le total '
        'de l\'école reste la somme de ses niveaux (D5)', () async {
      await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 100000);
      await insertCharge(
        'c2',
        's1',
        'TUITION',
        expected: 100000,
        paid: 0,
        level: 'lvl-2',
      );

      final rows = await dao.getFeeChargePositionsByLevel(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
      );

      expect(rows.length, 2);
      expect(
        pick(rows, student: 's1', level: 'lvl-1').status,
        StudentChargeStatus.paid,
      );
      expect(
        pick(rows, student: 's1', level: 'lvl-2').status,
        StudentChargeStatus.due,
      );
    });

    test('une créance SANS niveau est conservée, sous un niveau nul — la '
        'filtrer ferait disparaître un élève en silence', () async {
      await insertCharge('c1', 's1', 'TUITION', level: null, group: null);

      final rows = await dao.getFeeChargePositionsByLevel(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
      );

      expect(rows.single.schoolLevelId, isNull);
      expect(rows.single.studentId, 's1');
    });

    test('le filtre de cycle borne la population', () async {
      await insertCharge('c1', 's1', 'TUITION');
      await insertCharge('c2', 's2', 'TUITION', level: 'lvl-9', group: 'grp-2');

      final scoped = await dao.getFeeChargePositionsByLevel(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
        schoolLevelGroupId: 'grp-1',
      );
      final all = await dao.getFeeChargePositionsByLevel(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
      );

      expect(scoped.map((r) => r.studentId), ['s1']);
      expect(all.map((r) => r.studentId).toSet(), {'s1', 's2'});
    });

    test('sans cycle, AUCUN null ne part en whereArgs — sqflite le refuserait '
        'à l\'exécution', () async {
      await insertCharge('c1', 's1', 'TUITION', group: null);

      // La panne serait une exception, pas un résultat faux : c'est la clause
      // conditionnelle qui est sous test, et rien d'autre ne la prouve.
      final rows = await dao.getFeeChargePositionsByLevel(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
      );

      expect(rows.single.studentId, 's1');
    });

    test('une créance sans année vaut pour l\'année demandée ; celle d\'un '
        'autre exercice est écartée', () async {
      await insertCharge('c1', 's1', 'TUITION', year: null);
      await insertCharge('c2', 's2', 'TUITION', year: 'ay-2');

      final rows = await dao.getFeeChargePositionsByLevel(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
      );

      expect(rows.map((r) => r.studentId), ['s1']);
    });

    test('aucune créance de ce frais → liste vide, pas d\'erreur', () async {
      await insertCharge('c1', 's1', 'CANTINE');

      expect(
        await dao.getFeeChargePositionsByLevel(
          academicYearId: 'ay-1',
          feeCode: 'TUITION',
        ),
        isEmpty,
      );
    });
  });
}
