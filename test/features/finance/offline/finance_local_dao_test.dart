import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart'
    show GeneratedDocumentLocalModel;
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';

import '../../offline_full_db.dart';

/// IdGenerator déterministe pour les tests.
class SeqIdGenerator extends IdGenerator {
  SeqIdGenerator() : super(const Uuid());
  int _i = 0;
  @override
  String newId() => 'id-${_i++}';
}

void main() {
  late Database db;
  late FinanceLocalDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = FinanceLocalDao(db, SeqIdGenerator());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertTariff(
    String id,
    String feeCode,
    int amount, {
    String level = 'lvl-1',
    String? dueAt,
  }) => db.insert('ref_fee_tariffs', {
    'id': id,
    'fee_code': feeCode,
    'label': feeCode,
    'amount_in_cents': amount,
    'currency': 'USD',
    'school_level_id': level,
    'academic_year_id': 'ay-1',
    'due_at': dueAt,
  });

  Future<void> insertCharge(
    String id,
    String studentId,
    String feeCode, {
    int expected = 100000,
    int paid = 0,
    String status = 'DUE',
  }) => db.insert('student_charges', {
    'id': id,
    'student_id': studentId,
    'fee_code': feeCode,
    'label': feeCode,
    'expected_amount_in_cents': expected,
    'amount_paid_in_cents': paid,
    'optimistic_paid_in_cents': paid,
    'currency': 'USD',
    'status': status,
    'sync_status': 'SYNCED',
  });

  group('upsertLedger (FF7 hydratation)', () {
    test('gros grand-livre (> taille de lot) : toutes les créances appliquées '
        'à travers plusieurs lots', () async {
      // 250 > kPullApplyBatchSize (100) → au moins 3 lots (le verrou est relâché
      // entre les lots) ; garantit qu'aucune créance n'est perdue à la frontière.
      const count = 250;
      await dao.upsertLedger(
        charges: [
          for (var i = 0; i < count; i++)
            StudentChargeLocalModel(
              id: 'ch-$i',
              studentId: 'stu-$i',
              feeCode: 'TUITION',
              label: 'Scolarité',
              expectedAmountInCents: 100000,
              currency: 'USD',
            ),
        ],
      );

      expect(await db.query('student_charges'), hasLength(count));
      expect(await dao.getChargesByStudent('stu-0'), hasLength(1));
      expect(await dao.getChargesByStudent('stu-249'), hasLength(1));
    });
  });

  group('recordPayment (FF3)', () {
    test('insère payment(PENDING) + allocations (aucun UPDATE créance), RC '
        'provisoire, outbox(PAYMENT) ; reste composé au read', () async {
      await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 0);

      await dao.recordPayment(
        payment: const PaymentLocalModel(
          id: 'pay1',
          clientUuid: 'pay1',
          studentId: 's1',
          academicYearId: 'ay-1',
          amountInCents: 30000,
          currency: 'USD',
          method: 'MOBILE_MONEY',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'Sarah',
          payerLastName: 'Moke',
        ),
        allocations: const [
          PaymentAllocationLocalModel(
            id: 'a1',
            clientUuid: 'a1',
            paymentId: 'pay1',
            studentChargeId: 'c1',
            feeCode: 'TUITION',
            studentChargeLabel: 'Scolarité',
            amountInCents: 30000,
            currency: 'USD',
          ),
        ],
        receipt: const GeneratedDocumentLocalModel(
          id: 'rc1',
          docDomain: 'PAYMENT',
          paymentId: 'pay1',
          studentId: 's1',
          docType: 'RC',
          number: 'PROV-PAY1',
        ),
        outboxEntryId: 'ob-pay',
        nowMs: 1000,
      );

      final pay = (await db.query('payments')).first;
      expect(pay['sync_status'], SyncState.pendingSync.dbValue);
      expect(pay['method'], 'MOBILE_MONEY');

      final charge = (await db.query('student_charges')).first;
      expect(charge['amount_paid_in_cents'], 0, reason: 'autoritaire intact');
      expect(
        charge['optimistic_paid_in_cents'],
        0,
        reason: 'colonne gelée : plus jamais incrémentée (FRONT §8)',
      );

      // Le reste se COMPOSE à la lecture : 100000 − 0(miroir) − 30000(pending).
      final composed = (await dao.getChargesByStudent('s1')).single;
      expect(composed.amountPaidInCents, 0, reason: 'miroir serveur');
      expect(
        composed.amountPaidPendingInCents,
        30000,
        reason: 'pending composé',
      );
      expect(composed.optimisticRemainingInCents, 70000);

      final rc = (await db.query('generated_documents')).first;
      expect(rc['doc_type'], 'RC');
      expect(rc['status'], 'PROVISIONAL');

      final ob = (await db.query('outbox')).first;
      expect(ob['aggregate_type'], 'PAYMENT');
      expect(ob['aggregate_id'], 'pay1');
      final payload =
          jsonDecode(ob['payload'] as String) as Map<String, dynamic>;
      expect(payload['id'], 'pay1');
      expect(payload['clientUuid'], 'pay1');
      expect(payload['allocations'], hasLength(1));
    });
  });

  group('initializeChargesForStudent (FF5)', () {
    test(
      'réplique la grille filtrée par niveau → créances provisoires DUE',
      () async {
        await insertTariff('t1', 'TUITION', 100000, dueAt: '2026-12-31');
        await insertTariff('t2', 'CANTEEN', 20000);
        await insertTariff('t3', 'TUITION', 999, level: 'other-level');

        final charges = await dao.initializeChargesForStudent(
          studentId: 's1',
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-1',
          dueFallback: '2027-06-30',
          nowMs: 1000,
        );

        expect(charges, hasLength(2), reason: 'niveau other-level exclu');
        expect(
          charges.every((c) => c.status == StudentChargeStatus.due),
          isTrue,
        );
        expect(charges.every((c) => c.isProvisional), isTrue);
        expect(
          await db.query('outbox'),
          isEmpty,
          reason: 'créances provisoires JAMAIS poussées (FRONT §5.2)',
        );
        final stored = await db.query('student_charges');
        expect(
          stored.every((r) => r['sync_status'] == 'PROVISIONAL'),
          isTrue,
          reason: 'PROVISIONAL, distinct de PENDING_SYNC',
        );

        final tuition = charges.firstWhere((c) => c.feeCode == 'TUITION');
        expect(tuition.expectedAmountInCents, 100000);
        expect(tuition.dueAt, '2026-12-31');
        final canteen = charges.firstWhere((c) => c.feeCode == 'CANTEEN');
        expect(canteen.dueAt, '2027-06-30', reason: 'fallback endDate');
      },
    );
  });

  group('applyPaymentAck (FF4 remap)', () {
    test('remap créance provisoire→réelle par (student,feeCode) + écrase le '
        'solde autoritaire', () async {
      // Créance provisoire (uuid local) pour un nouvel élève.
      await db.insert('student_charges', {
        'id': 'prov-charge',
        'student_id': 's1',
        'fee_code': 'TUITION',
        'label': 'Scolarité',
        'expected_amount_in_cents': 100000,
        'amount_paid_in_cents': 0,
        'optimistic_paid_in_cents': 30000,
        'currency': 'USD',
        'status': 'DUE',
        'sync_status': 'PENDING_SYNC',
      });
      await dao.recordPayment(
        payment: const PaymentLocalModel(
          id: 'pay1',
          clientUuid: 'pay1',
          studentId: 's1',
          amountInCents: 30000,
          currency: 'USD',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'S',
          payerLastName: 'M',
        ),
        allocations: const [
          PaymentAllocationLocalModel(
            id: 'a1',
            clientUuid: 'a1',
            paymentId: 'pay1',
            studentChargeId: 'prov-charge',
            feeCode: 'TUITION',
            studentChargeLabel: 'Scolarité',
            amountInCents: 30000,
            currency: 'USD',
          ),
        ],
        outboxEntryId: 'ob-pay',
        nowMs: 1000,
      );

      await dao.applyPaymentAck(
        const PaymentCommitAck(
          paymentId: 'pay1',
          payment: AckPayment(id: 'pay1', status: 'CONFIRMED'),
          allocations: [
            AckAllocation(id: 'a1', studentChargeId: 'real-charge'),
          ],
          updatedCharges: [
            AckCharge(
              id: 'real-charge',
              amountPaidInCents: 30000,
              status: 'PARTIAL',
            ),
          ],
        ),
        nowMs: 5000,
      );

      // La créance provisoire a été remappée vers l'id réel.
      final charges = await db.query('student_charges');
      expect(charges, hasLength(1));
      expect(charges.first['id'], 'real-charge');
      expect(charges.first['amount_paid_in_cents'], 30000);
      expect(charges.first['status'], 'PARTIAL');
      expect(charges.first['sync_status'], SyncState.synced.dbValue);

      // L'allocation pointe désormais la créance réelle.
      final alloc = (await db.query('payment_allocations')).first;
      expect(alloc['student_charge_id'], 'real-charge');

      // Le paiement est SYNCED.
      expect(
        (await db.query('payments')).first['sync_status'],
        SyncState.synced.dbValue,
      );
    });

    test(
      'rejeu du même ACK : solde inchangé (idempotence money-grade)',
      () async {
        await insertCharge('real-charge', 's1', 'TUITION', paid: 0);
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            amountInCents: 30000,
            currency: 'USD',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
          ),
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a1',
              clientUuid: 'a1',
              paymentId: 'pay1',
              studentChargeId: 'real-charge',
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
          outboxEntryId: 'ob-pay',
          nowMs: 1000,
        );

        const ack = PaymentCommitAck(
          paymentId: 'pay1',
          payment: AckPayment(id: 'pay1'),
          allocations: [
            AckAllocation(id: 'a1', studentChargeId: 'real-charge'),
          ],
          updatedCharges: [
            AckCharge(
              id: 'real-charge',
              amountPaidInCents: 30000,
              status: 'PARTIAL',
            ),
          ],
        );
        await dao.applyPaymentAck(ack, nowMs: 5000);
        await dao.applyPaymentAck(ack, nowMs: 6000);

        final charge = (await db.query('student_charges')).first;
        expect(charge['amount_paid_in_cents'], 30000, reason: 'pas de double');
      },
    );
  });

  group('lectures — reste composé au read (FRONT §5)', () {
    test(
      'getChargesByStudent expose le reste composé (miroir − pending)',
      () async {
        await insertCharge(
          'c1',
          's1',
          'TUITION',
          expected: 100000,
          paid: 40000,
        );
        final charges = await dao.getChargesByStudent('s1');
        expect(
          charges.single.amountPaidInCents,
          40000,
          reason: 'miroir serveur',
        );
        expect(
          charges.single.amountPaidPendingInCents,
          0,
          reason: 'rien en file',
        );
        expect(charges.single.optimisticRemainingInCents, 60000);
      },
    );

    test('inclut les paiements SYNC_ERROR : le cash reçu ne réapparaît pas '
        '« à payer » (bug money-grade dissous)', () async {
      await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 0);
      await dao.recordPayment(
        payment: const PaymentLocalModel(
          id: 'pay-err',
          clientUuid: 'pay-err',
          studentId: 's1',
          amountInCents: 30000,
          currency: 'USD',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'S',
          payerLastName: 'M',
        ),
        allocations: const [
          PaymentAllocationLocalModel(
            id: 'a-err',
            clientUuid: 'a-err',
            paymentId: 'pay-err',
            studentChargeId: 'c1',
            feeCode: 'TUITION',
            studentChargeLabel: 'Scolarité',
            amountInCents: 30000,
            currency: 'USD',
          ),
        ],
        outboxEntryId: 'ob-err',
        nowMs: 1000,
      );
      // Échec technique de synchro — l'argent a pourtant été reçu au guichet.
      await db.update(
        'payments',
        {'sync_status': 'SYNC_ERROR'},
        where: 'id = ?',
        whereArgs: ['pay-err'],
      );

      final charge = (await dao.getChargesByStudent('s1')).single;
      expect(
        charge.amountPaidPendingInCents,
        30000,
        reason: 'SYNC_ERROR <> SYNCED → toujours déduit',
      );
      expect(charge.optimisticRemainingInCents, 70000);
    });

    test('totaux par devise (jamais de mélange USD/CDF)', () async {
      await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 40000);
      await db.insert('student_charges', {
        'id': 'c2',
        'student_id': 's1',
        'fee_code': 'CANTEEN',
        'label': 'Cantine',
        'expected_amount_in_cents': 50000,
        'amount_paid_in_cents': 0,
        'optimistic_paid_in_cents': 0,
        'currency': 'CDF',
        'status': 'DUE',
        'sync_status': 'SYNCED',
      });

      final totals = LocalStudentLedgerTotals.byCurrency(
        await dao.getChargesByStudent('s1'),
      );
      expect(totals, hasLength(2));
      final usd = totals.firstWhere((t) => t.currency == 'USD');
      expect(usd.totalDueInCents, 100000);
      expect(usd.totalPaidInCents, 40000);
      expect(usd.totalRemainingInCents, 60000);
      final cdf = totals.firstWhere((t) => t.currency == 'CDF');
      expect(cdf.totalRemainingInCents, 50000);
    });
  });

  group('replaceTariffsForYears (FF2 pull scopé)', () {
    FeeTariffLocalModel tariff(String id, {String year = 'ay-1'}) =>
        FeeTariffLocalModel(
          id: id,
          academicYearId: year,
          feeCode: 'INSCRIPTION',
          label: 'Inscription',
          amountInCents: 5000,
          currency: 'USD',
          updatedAt: 10,
        );

    Future<List<Object?>> tariffIdsFor(String year) async => (await db.query(
      'ref_fee_tariffs',
      columns: ['id'],
      where: 'academic_year_id = ?',
      whereArgs: [year],
    )).map((r) => r['id']).toList();

    test('purge les tarifs disparus de l\'année scopée, garde les autres '
        'années', () async {
      await insertTariff('t1', 'INSCRIPTION', 5000); // ay-1
      await insertTariff('t2', 'TUITION', 9000); // ay-1
      await db.insert('ref_fee_tariffs', {
        'id': 't-other',
        'fee_code': 'INSCRIPTION',
        'label': 'INSCRIPTION',
        'amount_in_cents': 5000,
        'currency': 'USD',
        'academic_year_id': 'ay-2',
      });

      // Nouveau bundle ay-1 : garde t2, ajoute t3, laisse tomber t1.
      await dao.replaceTariffsForYears(
        [tariff('t2'), tariff('t3')],
        academicYearIds: ['ay-1'],
      );

      expect((await tariffIdsFor('ay-1')).toSet(), {'t2', 't3'}); // t1 purgé
      expect(await tariffIdsFor('ay-2'), [
        't-other',
      ]); // année non scopée intacte
    });

    test(
      'bundle vide pour une année → vide cette année (tarif retiré serveur)',
      () async {
        await insertTariff('t1', 'INSCRIPTION', 5000);
        await dao.replaceTariffsForYears([], academicYearIds: ['ay-1']);
        expect(await tariffIdsFor('ay-1'), isEmpty);
      },
    );

    test('grande grille (> 2x taille de lot) : purge complète sans dépasser '
        'SQLITE_MAX_VARIABLE_NUMBER', () async {
      // 1200 > 2x _deleteChunkSize (500) → la purge traverse ≥3 lots de DELETE ;
      // le test garantit qu'aucune ligne n'est perdue ni oubliée aux frontières.
      final batch = db.batch();
      for (var i = 0; i < 1200; i++) {
        batch.insert('ref_fee_tariffs', {
          'id': 't-$i',
          'fee_code': 'FEE',
          'label': 'FEE',
          'amount_in_cents': 100,
          'currency': 'USD',
          'academic_year_id': 'ay-1',
        });
      }
      await batch.commit(noResult: true);

      await dao.replaceTariffsForYears(
        [tariff('t-42')],
        academicYearIds: ['ay-1'],
      );

      expect((await tariffIdsFor('ay-1')).toSet(), {'t-42'}); // 1199 purgés
    });
  });
}
