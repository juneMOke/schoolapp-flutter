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
    test('insère payment(PENDING) + allocations, met à jour l\'optimiste, RC '
        'provisoire, outbox(PAYMENT)', () async {
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
        30000,
        reason: 'optimiste += ',
      );

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

  group('lectures', () {
    test('getChargesByStudent expose le solde optimiste + reste', () async {
      await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 40000);
      final charges = await dao.getChargesByStudent('s1');
      expect(charges.single.optimisticRemainingInCents, 60000);
    });
  });
}
