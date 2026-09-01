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
import 'package:school_app_flutter/features/finance/offline/data/mappers/local_finance_online_mappers.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart'
    show StudentChargeDto;
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
    String? level = 'lvl-1',
    String year = 'ay-1',
    String? group,
    String? dueAt,
  }) => db.insert('ref_fee_tariffs', {
    'id': id,
    'fee_code': feeCode,
    'label': feeCode,
    'amount_in_cents': amount,
    'currency': 'USD',
    'school_level_id': level,
    'school_level_group_id': group,
    'academic_year_id': year,
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

  /// Créance autoritaire de l'ACK — même schéma `StudentCharge` que le pull.
  StudentChargeDto ackCharge(
    String id, {
    String studentId = 's1',
    String feeCode = 'TUITION',
    String? academicYearId,
    String? feeTariffId,
    int expected = 100000,
    int paid = 0,
    String status = 'PARTIAL',
  }) => StudentChargeDto(
    id: id,
    studentId: studentId,
    academicYearId: academicYearId,
    feeTariffId: feeTariffId,
    feeCode: feeCode,
    label: feeCode,
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    currency: 'USD',
    status: status,
  );

  /// ACK du push `POST /api/v1/sync/payments` pour le paiement `pay1`.
  PaymentAggregateResponse ackOf({
    String paymentId = 'pay1',
    List<AllocationRemap> allocations = const [],
    List<StudentChargeDto> charges = const [],
    List<GeneratedDocumentDto> documents = const [],
  }) => PaymentAggregateResponse(
    payment: AckPaymentRef(id: paymentId),
    allocations: allocations,
    charges: charges,
    documents: documents,
  );

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

    test(
      'créance canonique tirée du serveur : la jumelle PROVISIONAL (uuid local, '
      'élève inscrit hors-ligne) est dissoute — jamais de frais facturé 2 fois',
      () async {
        // Créance générée hors-ligne à l'inscription (uuid local).
        await db.insert('student_charges', {
          'id': 'prov-local',
          'student_id': 's1',
          'academic_year_id': 'ay-1',
          'fee_code': 'TUITION',
          'label': 'Scolarité',
          'expected_amount_in_cents': 500000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'USD',
          'status': 'DUE',
          'sync_status': SyncState.provisional.dbValue,
        });
        // Une imputation pointe la jumelle : elle doit suivre l'id canonique.
        await db.insert('payments', {
          'id': 'pay1',
          'client_uuid': 'pay1',
          'student_id': 's1',
          'paid_at': '2026-07-06T10:00:00Z',
          'payer_first_name': 'S',
          'payer_last_name': 'M',
          'sync_status': 'PENDING_SYNC',
        });
        await db.insert('payment_allocations', {
          'id': 'a1',
          'client_uuid': 'a1',
          'payment_id': 'pay1',
          'student_charge_id': 'prov-local',
          'fee_code': 'TUITION',
          'student_charge_label': 'Scolarité',
          'amount_in_cents': 20000,
          'currency': 'USD',
        });

        // Le serveur régénère la même créance avec son id canonique.
        await dao.upsertLedger(
          charges: const [
            StudentChargeLocalModel(
              id: 'server-canon',
              studentId: 's1',
              academicYearId: 'ay-1',
              feeCode: 'TUITION',
              label: 'Scolarité',
              expectedAmountInCents: 500000,
              currency: 'USD',
              status: 'DUE',
              syncStatus: 'SYNCED',
            ),
          ],
        );

        final rows = await db.query('student_charges');
        expect(rows, hasLength(1), reason: 'la jumelle a fondu');
        expect(rows.single['id'], 'server-canon');
        // Le reste à payer n'est PAS doublé.
        final charges = await dao.getChargesByStudent('s1');
        expect(charges, hasLength(1));
        expect(charges.single.expectedAmountInCents, 500000);
        // L'imputation suit la créance canonique (rien n'est orphelin).
        expect(
          (await db.query('payment_allocations')).single['student_charge_id'],
          'server-canon',
        );
      },
    );

    /// Sept tranches de minerval, sept créances de MÊME nature. Sans le tarif,
    /// la première canonique du lot avalait la provisoire — n'importe laquelle —
    /// et emportait ses imputations : le parent voyait la 1/3 soldée et la 2/3,
    /// qu'il venait de payer, toujours due.
    test(
      'trois tranches d\'un même frais : chaque canonique dissout SA jumelle, '
      'par tarif — l\'argent ne change pas de tranche',
      () async {
        for (final tranche in [1, 2, 3]) {
          await db.insert('student_charges', {
            'id': 'prov-$tranche',
            'student_id': 's1',
            'academic_year_id': 'ay-1',
            'fee_tariff_id': 'tarif-$tranche',
            'fee_code': 'EXAMINATION',
            'label': 'Organisation matériel examens — $tranche/3',
            'expected_amount_in_cents': 500000,
            'amount_paid_in_cents': 0,
            'optimistic_paid_in_cents': 0,
            'currency': 'CDF',
            'status': 'DUE',
            'sync_status': SyncState.provisional.dbValue,
          });
        }
        await db.insert('payments', {
          'id': 'pay1',
          'client_uuid': 'pay1',
          'student_id': 's1',
          'paid_at': '2026-07-06T10:00:00Z',
          'payer_first_name': 'S',
          'payer_last_name': 'M',
          'sync_status': 'PENDING_SYNC',
        });
        // Le guichet a encaissé la DEUXIÈME tranche — ni la première, ni la
        // dernière : la seule qu'aucun repli implicite ne devinerait juste.
        await db.insert('payment_allocations', {
          'id': 'a1',
          'client_uuid': 'a1',
          'payment_id': 'pay1',
          'student_charge_id': 'prov-2',
          'fee_tariff_id': 'tarif-2',
          'fee_code': 'EXAMINATION',
          'student_charge_label': 'Organisation matériel examens — 2/3',
          'amount_in_cents': 500000,
          'currency': 'CDF',
        });

        await dao.upsertLedger(
          charges: const [
            StudentChargeLocalModel(
              id: 'canon-1',
              studentId: 's1',
              academicYearId: 'ay-1',
              feeTariffId: 'tarif-1',
              feeCode: 'EXAMINATION',
              label: 'Organisation matériel examens — 1/3',
              expectedAmountInCents: 500000,
              currency: 'CDF',
              status: 'DUE',
              syncStatus: 'SYNCED',
            ),
            StudentChargeLocalModel(
              id: 'canon-2',
              studentId: 's1',
              academicYearId: 'ay-1',
              feeTariffId: 'tarif-2',
              feeCode: 'EXAMINATION',
              label: 'Organisation matériel examens — 2/3',
              expectedAmountInCents: 500000,
              currency: 'CDF',
              status: 'PARTIAL',
              syncStatus: 'SYNCED',
            ),
            StudentChargeLocalModel(
              id: 'canon-3',
              studentId: 's1',
              academicYearId: 'ay-1',
              feeTariffId: 'tarif-3',
              feeCode: 'EXAMINATION',
              label: 'Organisation matériel examens — 3/3',
              expectedAmountInCents: 500000,
              currency: 'CDF',
              status: 'DUE',
              syncStatus: 'SYNCED',
            ),
          ],
        );

        // Les trois provisoires ont fondu : aucune tranche n'est facturée deux
        // fois, et aucune n'a survécu au passage de sa voisine.
        final rows = await db.query('student_charges', orderBy: 'id');
        expect(rows.map((r) => r['id']), ['canon-1', 'canon-2', 'canon-3']);
        // Et l'argent est resté sur la tranche encaissée.
        expect(
          (await db.query('payment_allocations')).single['student_charge_id'],
          'canon-2',
        );
      },
    );

    /// Une base d'avant la v38, ou une créance *ad hoc* : la provisoire n'a pas
    /// de tarif. Elle reste dissoute — un doublon survivant se lit comme un
    /// frais dû de plus, ce qui est pire qu'une imputation approximative.
    test(
      'jumelle sans tarif (base d\'avant) : la nature suffit encore à la dissoudre',
      () async {
        await db.insert('student_charges', {
          'id': 'prov-sans-tarif',
          'student_id': 's1',
          'academic_year_id': 'ay-1',
          'fee_code': 'TUITION',
          'label': 'Scolarité',
          'expected_amount_in_cents': 500000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'USD',
          'status': 'DUE',
          'sync_status': SyncState.provisional.dbValue,
        });

        await dao.upsertLedger(
          charges: const [
            StudentChargeLocalModel(
              id: 'server-canon',
              studentId: 's1',
              academicYearId: 'ay-1',
              feeTariffId: 'tarif-1',
              feeCode: 'TUITION',
              label: 'Scolarité',
              expectedAmountInCents: 500000,
              currency: 'USD',
              status: 'DUE',
              syncStatus: 'SYNCED',
            ),
          ],
        );

        final rows = await db.query('student_charges');
        expect(rows, hasLength(1));
        expect(rows.single['id'], 'server-canon');
      },
    );

    test(
      'la créance SYNCED d\'une AUTRE année (même feeCode) n\'est jamais dissoute',
      () async {
        await db.insert('student_charges', {
          'id': 'charge-2024',
          'student_id': 's1',
          'academic_year_id': 'ay-2024',
          'fee_code': 'TUITION',
          'label': 'Scolarité 2024-25',
          'expected_amount_in_cents': 300000,
          'amount_paid_in_cents': 300000,
          'optimistic_paid_in_cents': 300000,
          'currency': 'USD',
          'status': 'PAID',
          'sync_status': SyncState.synced.dbValue,
        });

        await dao.upsertLedger(
          charges: const [
            StudentChargeLocalModel(
              id: 'charge-2025',
              studentId: 's1',
              academicYearId: 'ay-2025',
              feeCode: 'TUITION',
              label: 'Scolarité 2025-26',
              expectedAmountInCents: 500000,
              currency: 'USD',
              syncStatus: 'SYNCED',
            ),
          ],
        );

        expect(await db.query('student_charges'), hasLength(2));
      },
    );

    test(
      'le pull ne PIÉTINE pas les colonnes qu\'il ne porte pas : identité du '
      'payeur et libellé d\'allocation saisis au guichet sont conservés',
      () async {
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'Jean',
            payerLastName: 'Dupont',
            payerMiddleName: 'K',
          ),
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a1',
              clientUuid: 'a1',
              paymentId: 'pay1',
              studentChargeId: 'c1',
              feeCode: 'TUITION',
              studentChargeLabel: 'Minerval Trimestre 1',
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
          outboxEntryId: 'ob-1',
          nowMs: 1000,
        );

        // Le pull renvoie le même paiement : PaymentDelta ne porte NI le payeur
        // NI le libellé → les DTO replient sur '' / feeCode.
        await dao.upsertLedger(
          payments: const [
            PaymentLocalModel(
              id: 'pay1',
              clientUuid: 'pay1',
              studentId: 's1',
              paidAt: '2026-07-06T10:00:00Z',
              payerFirstName: '',
              payerLastName: '',
              syncStatus: 'SYNCED',
              syncedAt: 9000,
            ),
          ],
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a1',
              clientUuid: 'a1',
              paymentId: 'pay1',
              studentChargeId: 'c1',
              feeCode: 'TUITION',
              studentChargeLabel: 'TUITION', // repli du DTO
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
        );

        final payment = (await db.query('payments')).single;
        expect(payment['payer_first_name'], 'Jean');
        expect(payment['payer_last_name'], 'Dupont');
        expect(payment['payer_middle_name'], 'K');
        // Ce que le pull PORTE est bien appliqué (autorité serveur). Le
        // montant n'en fait plus partie : il vit sur les imputations, dont le
        // delta porte désormais la devise.
        expect(payment['paid_at'], isNotNull);

        expect(
          (await db.query(
            'payment_allocations',
          )).single['student_charge_label'],
          'Minerval Trimestre 1',
        );
      },
    );

    test(
      'paiement INCONNU (encaissé sur l\'autre poste) : inséré tel quel — le '
      'patch ne doit pas avaler la ligne',
      () async {
        await dao.upsertLedger(
          payments: const [
            PaymentLocalModel(
              id: 'pay-autre-poste',
              clientUuid: 'pay-autre-poste',
              studentId: 's9',
              paidAt: '2026-07-06T11:00:00Z',
              payerFirstName: '',
              payerLastName: '',
              syncStatus: 'SYNCED',
            ),
          ],
        );

        final rows = await db.query('payments');
        expect(rows, hasLength(1));
        expect(rows.single['id'], 'pay-autre-poste');
        // Ligne inconnue : c'est celle du serveur, elle EST synchronisée.
        expect(rows.single['sync_status'], SyncState.synced.dbValue);
      },
    );

    test(
      'le pull ne bascule JAMAIS un paiement local en SYNCED : seul l\'ACK le '
      'fait (sinon le montant sort du pending sur un miroir périmé → réencaisse)',
      () async {
        await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 0);
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
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
          outboxEntryId: 'ob-1',
          nowMs: 1000,
        );

        // Le pull ramène ce paiement (le serveur l'a) — le DTO est câblé SYNCED.
        await dao.upsertLedger(
          payments: const [
            PaymentLocalModel(
              id: 'pay1',
              clientUuid: 'pay1',
              studentId: 's1',
              paidAt: '2026-07-06T10:00:00Z',
              payerFirstName: '',
              payerLastName: '',
              syncStatus: 'SYNCED',
              syncedAt: 9000,
            ),
          ],
        );

        // L'état de synchro local reste celui de l'ACK / de l'outbox.
        expect(
          (await db.query('payments')).single['sync_status'],
          SyncState.pendingSync.dbValue,
        );
        // Donc le montant reste déduit : la créance n'est pas rendue « impayée »
        // alors que le caissier a déjà encaissé.
        final charge = (await dao.getChargesByStudent('s1')).single;
        expect(charge.amountPaidPendingInCents, 30000);
      },
    );

    test(
      'allocation : un studentChargeId NULL du pull (contrat nullable) n\'efface '
      'pas le lien déjà résolu',
      () async {
        await db.insert('payment_allocations', {
          'id': 'a1',
          'client_uuid': 'a1',
          'payment_id': 'pay1',
          'student_charge_id': 'c1', // résolu au versement
          'fee_code': 'TUITION',
          'student_charge_label': 'Scolarité',
          'amount_in_cents': 30000,
          'currency': 'USD',
        });

        await dao.upsertLedger(
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a1',
              clientUuid: 'a1',
              paymentId: 'pay1',
              studentChargeId: null, // absence d'info, pas une rétractation
              feeCode: 'TUITION',
              studentChargeLabel: 'TUITION',
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
        );

        expect(
          (await db.query('payment_allocations')).single['student_charge_id'],
          'c1',
        );
      },
    );

    test(
      'DEUX jumelles PROVISIONAL de même clé (initialize rejoué) : les deux sont '
      'dissoutes — une survivante facturerait le frais en double',
      () async {
        for (final id in ['prov-a', 'prov-b']) {
          await db.insert('student_charges', {
            'id': id,
            'student_id': 's1',
            'academic_year_id': 'ay-1',
            'fee_code': 'TUITION',
            'label': 'Scolarité',
            'expected_amount_in_cents': 500000,
            'amount_paid_in_cents': 0,
            'optimistic_paid_in_cents': 0,
            'currency': 'USD',
            'status': 'DUE',
            'sync_status': SyncState.provisional.dbValue,
          });
        }

        await dao.upsertLedger(
          charges: const [
            StudentChargeLocalModel(
              id: 'server-canon',
              studentId: 's1',
              academicYearId: 'ay-1',
              feeCode: 'TUITION',
              label: 'Scolarité',
              expectedAmountInCents: 500000,
              currency: 'USD',
              syncStatus: 'SYNCED',
            ),
          ],
        );

        final rows = await db.query('student_charges');
        expect(rows, hasLength(1), reason: 'aucune jumelle ne survit');
        expect(rows.single['id'], 'server-canon');
      },
    );
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
      // Payload = l'agrégat IMBRIQUÉ du contrat 1.1.0 (`{payment, allocations}`).
      final payload =
          jsonDecode(ob['payload'] as String) as Map<String, dynamic>;
      expect((payload['payment'] as Map)['id'], 'pay1'); // uuid client honoré
      expect((payload['payment'] as Map)['studentId'], 's1');
      expect(payload['allocations'], hasLength(1));
    });
  });

  group('recordPayment — re-résolution du lien de créance', () {
    test(
      'uuid PROVISIONAL périmé (jumelle dissoute pendant la saisie) : le lien '
      'est re-résolu par (élève, année, poste) — le montant reste déduit',
      () async {
        // La créance canonique a remplacé la jumelle pendant que le caissier
        // remplissait le formulaire ; l'UI tient encore l'uuid `prov-mort`.
        await db.insert('student_charges', {
          'id': 'server-canon',
          'student_id': 's1',
          'academic_year_id': 'ay-1',
          'fee_code': 'TUITION',
          'label': 'Scolarité',
          'expected_amount_in_cents': 100000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'USD',
          'status': 'DUE',
          'sync_status': SyncState.synced.dbValue,
        });

        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            academicYearId: 'ay-1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
          ),
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a1',
              clientUuid: 'a1',
              paymentId: 'pay1',
              studentChargeId: 'prov-mort', // uuid dissous
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
          outboxEntryId: 'ob-1',
          nowMs: 1000,
        );

        // Le lien local pointe la créance vivante…
        expect(
          (await db.query('payment_allocations')).single['student_charge_id'],
          'server-canon',
        );
        // …donc le reçu imprimé et le reste à payer sont cohérents : les 30 000
        // sont déduits, la créance ne réaffiche pas le montant entier.
        final charge = (await dao.getChargesByStudent('s1')).single;
        expect(charge.amountPaidPendingInCents, 30000);

        // Et le payload poussé porte le MÊME lien (pas l'uuid mort).
        final payload =
            jsonDecode((await db.query('outbox')).single['payload'] as String)
                as Map<String, dynamic>;
        final alloc = (payload['allocations'] as List).single as Map;
        expect(alloc['studentChargeId'], 'server-canon');
      },
    );

    test(
      'aucune créance locale pour ce poste : le lien tombe à null (« pas encore '
      'matérialisée ») plutôt que de garder un uuid mort — le serveur remappera',
      () async {
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            academicYearId: 'ay-1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
          ),
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a1',
              clientUuid: 'a1',
              paymentId: 'pay1',
              studentChargeId: 'prov-mort',
              feeCode: 'INSCRIPTION',
              studentChargeLabel: 'Inscription',
              amountInCents: 500,
              currency: 'USD',
            ),
          ],
          outboxEntryId: 'ob-1',
          nowMs: 1000,
        );

        expect(
          (await db.query('payment_allocations')).single['student_charge_id'],
          isNull,
        );
      },
    );

    /// Le tarif désigne la LIGNE DE GRILLE : c'est le seul discriminant quand
    /// l'élève doit trois fois le même frais. La nature, elle, en rapproche
    /// trois — et le `limit: 1` d'avant en retenait une au hasard de SQLite.
    test(
      'trois tranches en base, l\'imputation vise la 2/3 : le lien se re-résout '
      'par le TARIF, pas au hasard de la nature',
      () async {
        for (final tranche in [1, 2, 3]) {
          await db.insert('student_charges', {
            'id': 'canon-$tranche',
            'student_id': 's1',
            'academic_year_id': 'ay-1',
            'fee_tariff_id': 'tarif-$tranche',
            'fee_code': 'EXAMINATION',
            'label': 'Organisation matériel examens — $tranche/3',
            'expected_amount_in_cents': 500000,
            'amount_paid_in_cents': 0,
            'optimistic_paid_in_cents': 0,
            'currency': 'CDF',
            'status': 'DUE',
            'sync_status': SyncState.synced.dbValue,
          });
        }

        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            academicYearId: 'ay-1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
          ),
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a1',
              clientUuid: 'a1',
              paymentId: 'pay1',
              studentChargeId: 'prov-mort', // uuid dissous pendant la saisie
              feeTariffId: 'tarif-2',
              feeCode: 'EXAMINATION',
              studentChargeLabel: 'Organisation matériel examens — 2/3',
              amountInCents: 500000,
              currency: 'CDF',
            ),
          ],
          outboxEntryId: 'ob-1',
          nowMs: 1000,
        );

        expect(
          (await db.query('payment_allocations')).single['student_charge_id'],
          'canon-2',
        );
        // Le payload poussé porte le MÊME lien que le miroir local : le
        // diagnostic serveur ne peut pas diverger de ce que le guichet affiche.
        final payload =
            jsonDecode((await db.query('outbox')).single['payload'] as String)
                as Map<String, dynamic>;
        final alloc = (payload['allocations'] as List).single as Map;
        expect(alloc['studentChargeId'], 'canon-2');
        expect(alloc['feeTariffId'], 'tarif-2');
      },
    );

    /// Sans tarif — payload d'avant, ou créance *ad hoc* — la nature reste le
    /// seul repli. Elle ne tranche rien quand deux créances la portent : ne
    /// rien lier a un sens au contrat (« pas encore matérialisée », le serveur
    /// remappera), imputer au hasard n'en a aucun et le reçu imprimé le fige.
    test('deux candidates de même nature, aucun tarif : le lien tombe à null — '
        'jamais un tirage au sort', () async {
      for (final tranche in [1, 2]) {
        await db.insert('student_charges', {
          'id': 'canon-$tranche',
          'student_id': 's1',
          'academic_year_id': 'ay-1',
          'fee_tariff_id': 'tarif-$tranche',
          'fee_code': 'EXAMINATION',
          'label': 'Organisation matériel examens — $tranche/2',
          'expected_amount_in_cents': 500000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'CDF',
          'status': 'DUE',
          'sync_status': SyncState.synced.dbValue,
        });
      }

      await dao.recordPayment(
        payment: const PaymentLocalModel(
          id: 'pay1',
          clientUuid: 'pay1',
          studentId: 's1',
          academicYearId: 'ay-1',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'S',
          payerLastName: 'M',
        ),
        allocations: const [
          PaymentAllocationLocalModel(
            id: 'a1',
            clientUuid: 'a1',
            paymentId: 'pay1',
            studentChargeId: 'prov-mort',
            feeCode: 'EXAMINATION',
            studentChargeLabel: 'Organisation matériel examens',
            amountInCents: 500000,
            currency: 'CDF',
          ),
        ],
        outboxEntryId: 'ob-1',
        nowMs: 1000,
      );

      expect(
        (await db.query('payment_allocations')).single['student_charge_id'],
        isNull,
      );
    });

    test(
      'uuid encore vivant : le lien est laissé intact (aucune requête inutile)',
      () async {
        await insertCharge('c1', 's1', 'TUITION');
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
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
          outboxEntryId: 'ob-1',
          nowMs: 1000,
        );

        expect(
          (await db.query('payment_allocations')).single['student_charge_id'],
          'c1',
        );
      },
    );
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

    test(
      'rappel MÊME niveau → idempotent (aucune duplication, mêmes ids)',
      () async {
        await insertTariff('t1', 'TUITION', 100000);
        await insertTariff('t2', 'CANTEEN', 20000);

        final first = await dao.initializeChargesForStudent(
          studentId: 's1',
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-1',
          nowMs: 1000,
        );
        final second = await dao.initializeChargesForStudent(
          studentId: 's1',
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-1',
          nowMs: 2000,
        );

        expect(second, hasLength(2));
        expect(
          second.map((c) => c.id).toSet(),
          first.map((c) => c.id).toSet(),
          reason:
              'no-op : les créances existantes sont renvoyées telles quelles',
        );
        expect(await db.query('student_charges'), hasLength(2));
      },
    );

    test(
      'niveau cible modifié → régénère les provisoires sans allocation',
      () async {
        await insertTariff('t1', 'TUITION', 100000);
        await insertTariff('t2', 'TUITION-B', 120000, level: 'lvl-2');

        await dao.initializeChargesForStudent(
          studentId: 's1',
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-1',
          nowMs: 1000,
        );
        final regenerated = await dao.initializeChargesForStudent(
          studentId: 's1',
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-2',
          nowMs: 2000,
        );

        expect(regenerated, hasLength(1));
        expect(regenerated.single.feeCode, 'TUITION-B');
        expect(
          await db.query('student_charges'),
          hasLength(1),
          reason: 'les provisoires de l\'ancien niveau sont purgées',
        );
      },
    );

    test(
      'provisoire déjà IMPUTÉE (allocation) → conservée à la régénération',
      () async {
        await insertTariff('t1', 'TUITION', 100000);
        await insertTariff('t2', 'TUITION-B', 120000, level: 'lvl-2');

        final first = await dao.initializeChargesForStudent(
          studentId: 's1',
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-1',
          nowMs: 1000,
        );
        await db.insert('payment_allocations', {
          'id': 'alloc-1',
          'client_uuid': 'alloc-1',
          'payment_id': 'pay-1',
          'student_charge_id': first.single.id,
          'fee_code': 'TUITION',
          'student_charge_label': 'TUITION',
          'amount_in_cents': 30000,
          'currency': 'USD',
        });

        final regenerated = await dao.initializeChargesForStudent(
          studentId: 's1',
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-2',
          nowMs: 2000,
        );

        expect(
          regenerated.map((c) => c.feeCode).toSet(),
          {'TUITION', 'TUITION-B'},
          reason:
              'la créance payée survit (money-grade), la grille B s\'ajoute',
        );
        expect(await db.query('student_charges'), hasLength(2));
      },
    );

    test(
      'créance AUTORITAIRE présente (non provisoire) → no-op complet',
      () async {
        await insertTariff('t1', 'TUITION', 100000);
        await db.insert('student_charges', {
          'id': 'srv-charge',
          'student_id': 's1',
          'academic_year_id': 'ay-1',
          'school_level_id': 'lvl-1',
          'fee_code': 'TUITION',
          'label': 'Scolarité',
          'expected_amount_in_cents': 90000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'USD',
          'status': 'DUE',
          'sync_status': 'SYNCED',
        });

        final charges = await dao.initializeChargesForStudent(
          studentId: 's1',
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-1',
          nowMs: 1000,
        );

        expect(charges.single.id, 'srv-charge');
        expect(
          await db.query('student_charges'),
          hasLength(1),
          reason: 'le grand-livre serveur a la main : aucune génération locale',
        );
      },
    );

    test(
      'dueFallback absent → résolu depuis ref_academic_years.end_date',
      () async {
        await db.insert('ref_academic_years', {
          'id': 'ay-1',
          'name': '2026-2027',
          'end_date': '2027-07-02',
          'is_current': 1,
        });
        await insertTariff('t1', 'CANTEEN', 20000);

        final charges = await dao.initializeChargesForStudent(
          studentId: 's1',
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-1',
          nowMs: 1000,
        );

        expect(charges.single.dueAt, '2027-07-02');
      },
    );

    /// Le vrai trou, et il est en amont du guichet : un élève inscrit hors
    /// ligne ne devait qu'UNE tranche de minerval sur sept, sur l'appareil même
    /// qui l'a inscrit, jusqu'au pull suivant. Aucun tarif dans le payload
    /// d'encaissement ne répare cela — il désignerait une créance qui n'existe
    /// pas localement.
    test('plusieurs lignes de grille d\'une même nature → une créance PAR '
        'LIGNE, et le rappel n\'en duplique aucune', () async {
      for (final tranche in [1, 2, 3]) {
        await insertTariff('t$tranche', 'EXAMINATION', 500000);
      }

      final charges = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        nowMs: 1000,
      );

      expect(charges, hasLength(3));
      // Chacune désigne SA ligne de grille : c'est ce qui permettra au guichet
      // de dire sur quelle tranche l'argent a été reçu.
      expect(charges.map((c) => c.feeTariffId).toSet(), {'t1', 't2', 't3'});

      // Deuxième entrée sur l'étape Frais du wizard : les mêmes trois, mêmes
      // ids. La granularité par ligne de grille doit rester idempotente, sinon
      // chaque visite ajouterait trois créances de plus.
      final revisit = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        nowMs: 2000,
      );
      expect(
        revisit.map((c) => c.id).toSet(),
        charges.map((c) => c.id).toSet(),
      );
      expect(await db.query('student_charges'), hasLength(3));
    });

    test('MÊME fee_code aux deux niveaux + imputée conservée → JAMAIS de '
        'doublon de frais dans l\'année', () async {
      await insertTariff('t1', 'TUITION', 100000);
      await insertTariff('t2', 'TUITION', 120000, level: 'lvl-2');

      final first = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        nowMs: 1000,
      );
      // Encaissement sur la provisoire du niveau A → conservée au changement.
      await db.insert('payment_allocations', {
        'id': 'alloc-1',
        'client_uuid': 'alloc-1',
        'payment_id': 'pay-1',
        'student_charge_id': first.single.id,
        'fee_code': 'TUITION',
        'student_charge_label': 'TUITION',
        'amount_in_cents': 30000,
        'currency': 'USD',
      });

      final regenerated = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-2',
        nowMs: 2000,
      );

      expect(
        regenerated.single.id,
        first.single.id,
        reason: 'la TUITION payée survit, la grille B ne la double pas',
      );
      // Rejeux successifs : état stable (pas de réinsertion à chaque visite).
      final revisit = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-2',
        nowMs: 3000,
      );
      expect(revisit.single.id, first.single.id);
      expect(await db.query('student_charges'), hasLength(1));
    });

    test('tarif d\'une AUTRE année ignoré ; année NULL rattachée', () async {
      await insertTariff('t1', 'TUITION', 100000);
      await insertTariff('t2', 'TUITION-OLD', 80000, year: 'ay-0');
      await db.insert('ref_fee_tariffs', {
        'id': 't3',
        'fee_code': 'ASSURANCE',
        'label': 'ASSURANCE',
        'amount_in_cents': 5000,
        'currency': 'USD',
        'school_level_id': 'lvl-1',
        'academic_year_id': null,
      });

      final charges = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        nowMs: 1000,
      );

      expect(charges.map((c) => c.feeCode).toSet(), {'TUITION', 'ASSURANCE'});
    });

    test('tarif défini au CYCLE (school_level_id NULL) généré aussi', () async {
      await insertTariff('t1', 'TUITION', 100000);
      await insertTariff('t2', 'FRAIS-CYCLE', 15000, level: null, group: 'g1');
      await insertTariff('t3', 'AUTRE-CYCLE', 9000, level: null, group: 'g2');

      final charges = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        schoolLevelGroupId: 'g1',
        nowMs: 1000,
      );

      expect(
        charges.map((c) => c.feeCode).toSet(),
        {'TUITION', 'FRAIS-CYCLE'},
        reason: 'cycle g1 inclus, cycle g2 exclu',
      );
    });

    test('créance autoritaire à année NULL → no-op (rattachée à la lecture '
        'par année)', () async {
      await insertTariff('t1', 'TUITION', 100000);
      await db.insert('student_charges', {
        'id': 'legacy-charge',
        'student_id': 's1',
        'academic_year_id': null,
        'fee_code': 'TUITION',
        'label': 'Scolarité',
        'expected_amount_in_cents': 90000,
        'amount_paid_in_cents': 0,
        'optimistic_paid_in_cents': 0,
        'currency': 'USD',
        'status': 'DUE',
        'sync_status': 'SYNCED',
      });

      final charges = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        nowMs: 1000,
      );

      expect(charges.single.id, 'legacy-charge');
      expect(await db.query('student_charges'), hasLength(1));
    });

    test('tarif ajouté à la grille après coup → top-up sans doubler '
        'l\'existant', () async {
      await insertTariff('t1', 'TUITION', 100000);
      final first = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        nowMs: 1000,
      );

      await insertTariff('t2', 'CANTEEN', 20000);
      final second = await dao.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        nowMs: 2000,
      );

      expect(second, hasLength(2));
      expect(
        second.firstWhere((c) => c.feeCode == 'TUITION').id,
        first.single.id,
        reason: 'la créance existante garde son id (pas de régénération)',
      );
    });
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
        ackOf(
          allocations: const [
            AllocationRemap(
              providedId: 'a1',
              canonicalId: 'a1',
              providedStudentChargeId: 'prov-charge',
              canonicalStudentChargeId: 'real-charge',
              feeCode: 'TUITION',
            ),
          ],
          charges: [ackCharge('real-charge', paid: 30000, status: 'PARTIAL')],
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

        final ack = ackOf(
          allocations: const [
            AllocationRemap(
              providedId: 'a1',
              canonicalId: 'a1',
              canonicalStudentChargeId: 'real-charge',
              feeCode: 'TUITION',
            ),
          ],
          charges: [ackCharge('real-charge', paid: 30000, status: 'PARTIAL')],
        );
        await dao.applyPaymentAck(ack, nowMs: 5000);
        await dao.applyPaymentAck(ack, nowMs: 6000);

        final charge = (await db.query('student_charges')).first;
        expect(charge['amount_paid_in_cents'], 30000, reason: 'pas de double');
      },
    );

    test(
      'créance autoritaire INCONNUE de ce poste : upsertée, et sa jumelle '
      'PROVISIONAL (même student+feeCode) dissoute — jamais de frais en double',
      () async {
        // L'ACK d'un paiement sur INSCRIPTION renvoie AUSSI la créance TUITION
        // recalculée, dont ce poste ne connaît qu'une jumelle provisoire créée
        // offline à l'inscription (uuid local ≠ uuid serveur).
        await db.insert('student_charges', {
          'id': 'prov-tuition',
          'student_id': 's1',
          'fee_code': 'TUITION',
          'label': 'Scolarité',
          'expected_amount_in_cents': 100000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'USD',
          'status': 'DUE',
          'sync_status': SyncState.provisional.dbValue,
        });

        await dao.applyPaymentAck(
          ackOf(
            charges: [
              ackCharge(
                'server-tuition',
                feeCode: 'TUITION',
                paid: 0,
                status: 'UNPAID',
              ),
            ],
          ),
          nowMs: 5000,
        );

        final charges = await db.query('student_charges');
        expect(charges, hasLength(1), reason: 'la jumelle provisoire a fondu');
        expect(charges.single['id'], 'server-tuition');
        expect(charges.single['sync_status'], SyncState.synced.dbValue);
        // UNPAID (contrat) → DUE (vocabulaire local), comme au pull.
        expect(charges.single['status'], 'DUE');
      },
    );

    /// Le semis matérialise une créance PAR LIGNE DE GRILLE : trois tranches
    /// d'examen, trois provisoires de même nature. L'accusé n'en concerne
    /// qu'une — et la dissolution, si elle s'en tenait à la nature, effacerait
    /// les deux autres et ré-imputerait leurs versements sur elle. Six créances
    /// perdues sur sept dans le cas réel, sans un mot à l'écran.
    test('l\'accusé d\'UNE tranche ne dissout que la sienne — les voisines '
        'survivent avec leurs imputations', () async {
      for (final tranche in [1, 2, 3]) {
        await db.insert('student_charges', {
          'id': 'prov-$tranche',
          'student_id': 's1',
          'academic_year_id': 'ay-1',
          'fee_tariff_id': 'tarif-$tranche',
          'fee_code': 'EXAMINATION',
          'label': 'Organisation matériel examens — $tranche/3',
          'expected_amount_in_cents': 500000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'CDF',
          'status': 'DUE',
          'sync_status': SyncState.provisional.dbValue,
        });
      }
      // Un versement encaissé sur la TROISIÈME tranche, qui n'est pas celle
      // que l'accusé rapporte : il doit rester où il est.
      await db.insert('payment_allocations', {
        'id': 'alloc-3',
        'client_uuid': 'alloc-3',
        'payment_id': 'pay-autre',
        'student_charge_id': 'prov-3',
        'fee_tariff_id': 'tarif-3',
        'fee_code': 'EXAMINATION',
        'student_charge_label': 'Organisation matériel examens — 3/3',
        'amount_in_cents': 500000,
        'currency': 'CDF',
      });

      await dao.applyPaymentAck(
        ackOf(
          charges: [
            ackCharge(
              'canon-2',
              academicYearId: 'ay-1',
              feeTariffId: 'tarif-2',
              feeCode: 'EXAMINATION',
              expected: 500000,
              paid: 500000,
              status: 'PAID',
            ),
          ],
        ),
        nowMs: 5000,
      );

      final ids = (await db.query(
        'student_charges',
        columns: ['id'],
        orderBy: 'id',
      )).map((r) => r['id']).toList();
      expect(ids, ['canon-2', 'prov-1', 'prov-3']);
      expect(
        (await db.query('payment_allocations')).single['student_charge_id'],
        'prov-3',
        reason: 'le versement de la 3/3 n\'a pas migré vers la 2/3',
      );
    });

    test(
      'la créance SYNCED d\'une AUTRE année (même élève, même feeCode) est '
      'INTOUCHABLE : le rollover ne détruit pas le grand-livre N-1',
      () async {
        // 2024-25 : créance autoritaire soldée, conservée en local.
        await db.insert('student_charges', {
          'id': 'charge-2024',
          'student_id': 's1',
          'academic_year_id': 'ay-2024',
          'fee_code': 'TUITION',
          'label': 'Scolarité 2024-25',
          'expected_amount_in_cents': 300000,
          'amount_paid_in_cents': 300000,
          'optimistic_paid_in_cents': 300000,
          'currency': 'USD',
          'status': 'PAID',
          'sync_status': SyncState.synced.dbValue,
        });

        // ACK d'une créance 2025-26 pour le même élève et le même poste.
        await dao.applyPaymentAck(
          ackOf(
            charges: const [
              StudentChargeDto(
                id: 'charge-2025',
                studentId: 's1',
                academicYearId: 'ay-2025',
                feeCode: 'TUITION',
                label: 'Scolarité 2025-26',
                expectedAmountInCents: 500000,
                amountPaidInCents: 0,
                currency: 'USD',
                status: 'UNPAID',
              ),
            ],
          ),
          nowMs: 5000,
        );

        final rows = await db.query('student_charges', orderBy: 'id');
        expect(rows, hasLength(2), reason: 'les deux années coexistent');
        expect(rows.first['id'], 'charge-2024');
        expect(rows.first['amount_paid_in_cents'], 300000);
        expect(rows.first['academic_year_id'], 'ay-2024');
        expect(rows.last['id'], 'charge-2025');
      },
    );

    test(
      'canonicalId d\'allocation divergent : la clé primaire n\'est PAS réécrite '
      '(un rejeu après pull ne doit jamais faire échouer tout l\'ACK)',
      () async {
        await insertCharge('c1', 's1', 'TUITION');
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
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
          outboxEntryId: 'ob-pay',
          nowMs: 1000,
        );
        // La ligne canonique existe déjà (insérée par le pull des paiements
        // après un ACK perdu) → réécrire `a1` en `a-canon` violerait la PK.
        await db.insert('payment_allocations', {
          'id': 'a-canon',
          'client_uuid': 'a-canon',
          'payment_id': 'pay1',
          'student_charge_id': 'c1',
          'fee_code': 'TUITION',
          'student_charge_label': 'Scolarité',
          'amount_in_cents': 30000,
          'currency': 'USD',
        });

        await dao.applyPaymentAck(
          ackOf(
            allocations: const [
              AllocationRemap(
                providedId: 'a1',
                canonicalId: 'a-canon', // divergent → ignoré
                canonicalStudentChargeId: 'c1',
                feeCode: 'TUITION',
              ),
            ],
            charges: [ackCharge('c1', paid: 30000)],
          ),
          nowMs: 5000,
        );

        // L'ACK est allé au bout : le paiement est SYNCED (pas de rollback).
        expect(
          (await db.query('payments')).single['sync_status'],
          SyncState.synced.dbValue,
        );
        final ids = (await db.query(
          'payment_allocations',
          orderBy: 'id',
        )).map((r) => r['id']).toList();
        expect(ids, ['a-canon', 'a1'], reason: 'aucune PK réécrite');
      },
    );

    test(
      'remap sans créance canonique (champ optionnel absent — ligne en '
      'trop-perçu) : ce remap est sauté, l\'ACK va au bout et les AUTRES passent',
      () async {
        await insertCharge('c1', 's1', 'TUITION');
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
          ),
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a-lie',
              clientUuid: 'a-lie',
              paymentId: 'pay1',
              studentChargeId: 'c1',
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 20000,
              currency: 'USD',
            ),
            PaymentAllocationLocalModel(
              id: 'a-orphelin',
              clientUuid: 'a-orphelin',
              paymentId: 'pay1',
              feeCode: 'DIVERS',
              studentChargeLabel: 'Divers',
              amountInCents: 10000,
              currency: 'USD',
            ),
          ],
          outboxEntryId: 'ob-1',
          nowMs: 1000,
        );

        await dao.applyPaymentAck(
          ackOf(
            allocations: const [
              AllocationRemap(
                providedId: 'a-orphelin',
                canonicalId: 'a-orphelin',
                canonicalStudentChargeId: null, // le serveur n'a pas su lier
                feeCode: 'DIVERS',
              ),
              AllocationRemap(
                providedId: 'a-lie',
                canonicalId: 'a-lie',
                canonicalStudentChargeId: 'c1',
                feeCode: 'TUITION',
              ),
            ],
            charges: [ackCharge('c1', paid: 20000)],
          ),
          nowMs: 5000,
        );

        // L'ACK n'a pas été empoisonné : le paiement est acquitté.
        expect(
          (await db.query('payments')).single['sync_status'],
          SyncState.synced.dbValue,
        );
        final allocs = {
          for (final r in await db.query('payment_allocations'))
            r['id'] as String: r['student_charge_id'],
        };
        expect(allocs['a-lie'], 'c1'); // l'autre remap est bien passé
        expect(allocs['a-orphelin'], isNull); // laissé tel quel
      },
    );

    test(
      'scellement du reçu : le numéro définitif serveur remplace le PROV-… local',
      () async {
        await db.insert('generated_documents', {
          'id': 'doc-1',
          'doc_domain': 'PAYMENT',
          'payment_id': 'pay1',
          'student_id': 's1',
          'doc_type': 'RC',
          'number': 'PROV-ABCD1234',
          'status': 'PROVISIONAL',
          'created_at': 1000,
        });

        await dao.applyPaymentAck(
          ackOf(
            documents: const [
              GeneratedDocumentDto(
                type: 'PAYMENT_RECEIPT',
                documentNumber: 'ETL-RP-0042',
                status: 'DEFINITIVE',
              ),
            ],
          ),
          nowMs: 5000,
        );

        final doc = (await db.query('generated_documents')).single;
        expect(doc['number'], 'ETL-RP-0042');
        expect(doc['status'], 'DEFINITIVE');
      },
    );

    test(
      'ACK sans document (scellement best-effort en échec, décision G) : le reçu '
      'provisoire est CONSERVÉ, le paiement reste acquis (SYNCED)',
      () async {
        await db.insert('generated_documents', {
          'id': 'doc-1',
          'doc_domain': 'PAYMENT',
          'payment_id': 'pay1',
          'student_id': 's1',
          'doc_type': 'RC',
          'number': 'PROV-ABCD1234',
          'status': 'PROVISIONAL',
          'created_at': 1000,
        });
        await db.insert('payments', {
          'id': 'pay1',
          'client_uuid': 'pay1',
          'student_id': 's1',
          'paid_at': '2026-07-06T10:00:00Z',
          'payer_first_name': 'S',
          'payer_last_name': 'M',
          'sync_status': 'PENDING_SYNC',
        });

        // ACK normal (créances autoritaires présentes), mais SANS document.
        await dao.applyPaymentAck(
          ackOf(charges: [ackCharge('c1', paid: 30000)]),
          nowMs: 5000,
        );

        final doc = (await db.query('generated_documents')).single;
        expect(doc['number'], 'PROV-ABCD1234');
        expect(doc['status'], 'PROVISIONAL');
        expect(
          (await db.query('payments')).single['sync_status'],
          SyncState.synced.dbValue,
        );
      },
    );

    test(
      'ACK SANS créance autoritaire (panne serveur — `charges` est requis) : le '
      'paiement N\'est PAS acquitté, son montant reste déduit du reste à payer',
      () async {
        await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 0);
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay1',
            clientUuid: 'pay1',
            studentId: 's1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
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
          outboxEntryId: 'ob-1',
          nowMs: 1000,
        );

        await dao.applyPaymentAck(ackOf(), nowMs: 5000);

        // Acquitter sans miroir intégré sortirait les 30 000 du pending SANS
        // que `amount_paid` les porte → créance « impayée » → réencaissement.
        expect(
          (await db.query('payments')).single['sync_status'],
          SyncState.pendingSync.dbValue,
        );
        final charge = (await dao.getChargesByStudent('s1')).single;
        expect(charge.amountPaidPendingInCents, 30000);
      },
    );
  });

  /// v39 — la créance est **nommée** par la ligne de grille dont elle dépend.
  ///
  /// `student_charges` ne porte pas le code : le serveur ne le sert que sur le
  /// TARIF. Il se compose donc à la lecture, par jointure sur `fee_tariff_id`.
  group('lectures — le code du tarif, composé au read (v39)', () {
    Future<void> insertTariff(
      String id, {
      String? code,
      String feeCode = 'EXAMINATION',
      String label = 'Organisation matériel examens — 2/3',
    }) => db.insert('ref_fee_tariffs', {
      'id': id,
      'academic_year_id': 'ay-1',
      'school_level_id': 'lvl-1',
      'school_level_group_id': 'grp-1',
      'fee_code': feeCode,
      'code': code,
      'label': label,
      'amount_in_cents': 500000,
      'currency': 'CDF',
    });

    Future<void> insertChargeOnTariff(String id, {String? tariffId}) =>
        db.insert('student_charges', {
          'id': id,
          'student_id': 's1',
          'academic_year_id': 'ay-1',
          'fee_tariff_id': tariffId,
          'fee_code': 'EXAMINATION',
          'label': 'Organisation matériel examens — 2/3',
          'expected_amount_in_cents': 500000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'CDF',
          'status': 'DUE',
          'sync_status': 'SYNCED',
        });

    test('le code de la ligne de grille remonte jusqu\'à la créance', () async {
      await insertTariff('tar-om2', code: 'OM2');
      await insertChargeOnTariff('c-om2', tariffId: 'tar-om2');

      final charge = (await dao.getChargesByStudent('s1')).single;
      expect(charge.feeTariffCode, 'OM2');
    });

    /// Une créance *ad hoc* est hors grille : elle n'a légitimement pas de
    /// tarif, donc pas de code. Ce n'est pas une anomalie à signaler, c'est une
    /// créance qui se nomme par son seul libellé.
    test('créance sans tarif → code nul, et la ligne reste', () async {
      await insertChargeOnTariff('c-adhoc');

      final charges = await dao.getChargesByStudent('s1');
      expect(charges, hasLength(1));
      expect(charges.single.feeTariffCode, isNull);
    });

    /// LE test du lot. La grille est un CACHE : caviardée pour qui n'a pas
    /// `finance.grid.read`, purgée année par année par le pull. Une jointure
    /// STRICTE ferait alors disparaître des créances du grand-livre — de
    /// l'argent dû, effacé de l'écran pour un défaut d'affichage.
    test('tarif absent de l\'appareil → code nul, la créance survit', () async {
      await insertChargeOnTariff('c-orpheline', tariffId: 'tar-jamais-pullé');

      final charges = await dao.getChargesByStudent('s1');
      expect(charges, hasLength(1), reason: 'LEFT JOIN, jamais JOIN');
      expect(charges.single.id, 'c-orpheline');
      expect(charges.single.feeTariffCode, isNull);
      expect(charges.single.expectedAmountInCents, 500000);
    });

    /// Le tarif d'avant le pull qui a rempli la colonne : la ligne existe, son
    /// code est vide. Rien ne doit lever, et la désignation retombe sur le
    /// libellé — c'est-à-dire sur le comportement d'avant la v39.
    test('tarif joint mais sans code → nul, sans lever', () async {
      await insertTariff('tar-sans-code');
      await insertChargeOnTariff('c-1', tariffId: 'tar-sans-code');

      final charge = (await dao.getChargesByStudent('s1')).single;
      expect(charge.feeTariffCode, isNull);
    });

    /// Deux tranches de la MÊME nature : c'est le cas qui a motivé tout le
    /// chantier. Chacune doit rapporter SON code, pas celui de sa voisine.
    test('deux tranches d\'une même nature portent chacune son code', () async {
      await insertTariff('tar-om1', code: 'OM1');
      await insertTariff('tar-om3', code: 'OM3');
      await insertChargeOnTariff('c-om1', tariffId: 'tar-om1');
      await insertChargeOnTariff('c-om3', tariffId: 'tar-om3');

      final charges = await dao.getChargesByStudent('s1');
      expect(charges, hasLength(2));
      expect(
        {for (final c in charges) c.id: c.feeTariffCode},
        {'c-om1': 'OM1', 'c-om3': 'OM3'},
      );
    });

    /// Le pont local→online aplatit `feeTariffId` absent en `''` (c'est la forme
    /// qu'attendent les écrans de lecture). Le CODE, lui, ne doit pas l'être :
    /// un écran n'en fait qu'une chose, décider s'il l'affiche, et `''` y
    /// ajouterait un troisième cas.
    test('le mapper online n\'aplatit pas le code en chaîne vide', () async {
      await insertChargeOnTariff('c-adhoc');

      final online = (await dao.getChargesByStudent(
        's1',
      )).single.toOnlineEntity();
      expect(online.feeTariffCode, isNull);
      expect(online.feeTariffId, '', reason: 'l\'id, lui, reste aplati');
    });

    /// v39 / NC-5 — **l'ordre des tranches**.
    ///
    /// Le tri ne portait que sur `fee_code` : entre sept tranches d'un même
    /// minerval, il rendait l'ordre d'insertion de SQLite, et le guichet lisait
    /// « 3/3, 1/3, 2/3 ». Les nommer sans les ordonner déplaçait le problème.
    group('l\'ordre des tranches', () {
      Future<void> insertTranche(
        String id, {
        required String code,
        String? dueAt,
      }) async {
        await insertTariff('tar-$id', code: code);
        await db.insert('student_charges', {
          'id': id,
          'student_id': 's1',
          'academic_year_id': 'ay-1',
          'fee_tariff_id': 'tar-$id',
          'fee_code': 'EXAMINATION',
          'label': 'Organisation matériel examens',
          'expected_amount_in_cents': 500000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'CDF',
          'status': 'DUE',
          'due_at': dueAt,
          'sync_status': 'SYNCED',
        });
      }

      /// Insérées à REBOURS, exprès : si le tri tenait encore à l'ordre
      /// d'insertion, ce test le dirait. C'est la seule façon de prouver que
      /// c'est bien la clause `ORDER BY` qui travaille.
      test(
        'triées par échéance, quel que soit l\'ordre d\'insertion',
        () async {
          await insertTranche('c3', code: 'OM3', dueAt: '2027-05-31');
          await insertTranche('c1', code: 'OM1', dueAt: '2026-11-30');
          await insertTranche('c2', code: 'OM2', dueAt: '2027-02-28');

          final charges = await dao.getChargesByStudent('s1');
          expect([for (final c in charges) c.id], ['c1', 'c2', 'c3']);
        },
      );

      /// SQLite place les `NULL` en TÊTE d'un `ORDER BY … ASC`. Sans le
      /// `(due_at IS NULL) ASC` explicite, une tranche sans échéance passerait
      /// devant la première — celle que la famille doit régler en premier.
      test('une tranche sans échéance passe APRÈS celles qui en ont', () async {
        await insertTranche('c-sans', code: 'OM9');
        await insertTranche('c1', code: 'OM1', dueAt: '2026-11-30');

        final charges = await dao.getChargesByStudent('s1');
        expect([for (final c in charges) c.id], ['c1', 'c-sans']);
      });

      /// Même échéance sur deux tranches : c'est le code qui départage.
      test('à échéance égale, le code départage', () async {
        await insertTranche('cb', code: 'OM2', dueAt: '2027-02-28');
        await insertTranche('ca', code: 'OM1', dueAt: '2027-02-28');

        final charges = await dao.getChargesByStudent('s1');
        expect([for (final c in charges) c.id], ['ca', 'cb']);
      });

      /// Rien pour départager : le tri doit rester **stable**, pas arbitraire.
      /// Deux lectures de la même base rendent la même page — sinon un écran se
      /// réorganise tout seul entre deux rafraîchissements.
      test('sans échéance ni code, l\'ordre reste stable', () async {
        await insertChargeOnTariff('z-charge');
        await insertChargeOnTariff('a-charge');

        final first = await dao.getChargesByStudent('s1');
        final second = await dao.getChargesByStudent('s1');
        expect([for (final c in first) c.id], ['a-charge', 'z-charge']);
        expect([for (final c in second) c.id], [for (final c in first) c.id]);
      });

      /// La nature reste la clé de premier rang : les tranches d'un même frais
      /// se suivent, elles ne s'entrelacent pas avec celles d'un autre.
      test('la nature groupe avant tout le reste', () async {
        await insertTranche('exam-2', code: 'OM2', dueAt: '2027-02-28');
        await db.insert('student_charges', {
          'id': 'tuition-1',
          'student_id': 's1',
          'academic_year_id': 'ay-1',
          'fee_code': 'ASSURANCE',
          'label': 'Assurance',
          'expected_amount_in_cents': 10000,
          'amount_paid_in_cents': 0,
          'optimistic_paid_in_cents': 0,
          'currency': 'CDF',
          'status': 'DUE',
          'due_at': '2026-09-30',
          'sync_status': 'SYNCED',
        });
        await insertTranche('exam-1', code: 'OM1', dueAt: '2026-11-30');

        final charges = await dao.getChargesByStudent('s1');
        expect(
          [for (final c in charges) c.id],
          ['tuition-1', 'exam-1', 'exam-2'],
        );
      });
    });

    /// Les IMPUTATIONS aussi doivent nommer leur tranche : c'est le seul écran
    /// qui dit ce que le guichet a réellement encaissé, et deux versements sur
    /// deux tranches d'un même minerval s'y lisaient à l'identique.
    ///
    /// Le tarif vient de `payment_allocations.fee_tariff_id` (v38), FIGÉ à
    /// l'encaissement — jamais relu depuis la créance, qui peut avoir bougé.
    group('imputations', () {
      Future<void> recordAllocation({String? tariffId}) async {
        await db.insert('payments', {
          'id': 'pay-1',
          'client_uuid': 'pay-1',
          'student_id': 's1',
          'paid_at': '2026-07-06T10:00:00Z',
          'payer_first_name': 'S',
          'payer_last_name': 'M',
          'sync_status': 'SYNCED',
        });
        await db.insert('payment_allocations', {
          'id': 'alloc-1',
          'client_uuid': 'alloc-1',
          'payment_id': 'pay-1',
          'student_charge_id': 'c-om2',
          'fee_tariff_id': tariffId,
          'fee_code': 'EXAMINATION',
          'student_charge_label': 'Organisation matériel examens — 2/3',
          'amount_in_cents': 500000,
          'currency': 'CDF',
        });
      }

      test('le code remonte sur les deux lectures', () async {
        await insertTariff('tar-om2', code: 'OM2');
        await recordAllocation(tariffId: 'tar-om2');

        expect(
          (await dao.getAllocationsByPayment('pay-1')).single.feeTariffCode,
          'OM2',
        );
        expect(
          (await dao.getAllocationsByCharge('c-om2')).single.feeTariffCode,
          'OM2',
        );
      });

      /// Même garde que pour les créances, et le même enjeu : une imputation
      /// perdue, c'est de l'argent reçu qui disparaît de la répartition d'un
      /// versement — donc d'un reçu.
      test('tarif absent de l\'appareil → l\'imputation survit', () async {
        await recordAllocation(tariffId: 'tar-jamais-pullé');

        final allocations = await dao.getAllocationsByPayment('pay-1');
        expect(allocations, hasLength(1), reason: 'LEFT JOIN, jamais JOIN');
        expect(allocations.single.amountInCents, 500000);
        expect(allocations.single.feeTariffCode, isNull);
      });

      /// La répartition d'un versement se triait sur la seule nature : deux
      /// imputations d'un même minerval y sortaient dans l'ordre d'insertion.
      /// L'échéance n'a pas sa place ici — elle appartient à la créance, et
      /// ceci est la photo d'un versement.
      test('répartition triée par nature puis code de tranche', () async {
        await insertTariff('tar-om1', code: 'OM1');
        await insertTariff('tar-om3', code: 'OM3');
        await db.insert('payments', {
          'id': 'pay-2',
          'client_uuid': 'pay-2',
          'student_id': 's1',
          'paid_at': '2026-07-06T10:00:00Z',
          'payer_first_name': 'S',
          'payer_last_name': 'M',
          'sync_status': 'SYNCED',
        });
        // Insérées à rebours, comme pour les créances.
        for (final (id, tariff) in [('b', 'tar-om3'), ('a', 'tar-om1')]) {
          await db.insert('payment_allocations', {
            'id': id,
            'client_uuid': id,
            'payment_id': 'pay-2',
            'student_charge_id': 'c-$id',
            'fee_tariff_id': tariff,
            'fee_code': 'EXAMINATION',
            'student_charge_label': 'Organisation matériel examens',
            'amount_in_cents': 500000,
            'currency': 'CDF',
          });
        }

        final allocations = await dao.getAllocationsByPayment('pay-2');
        expect([for (final a in allocations) a.feeTariffCode], ['OM1', 'OM3']);
      });

      /// Versement d'avant la v38 : le payload était figé sans tarif, et la
      /// reprise n'a rien pu apparier. La répartition se lit quand même.
      test('imputation sans tarif → code nul, sans lever', () async {
        await recordAllocation();

        final allocation = (await dao.getAllocationsByPayment('pay-1')).single;
        expect(allocation.feeTariffCode, isNull);
        expect(
          allocation.studentChargeLabel,
          'Organisation matériel examens — 2/3',
          reason: 'le libellé gelé, lui, ne dépend pas de la grille',
        );
      });
    });
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

    test('getAllocationsByPayment replie payeur + date (cohérent avec '
        'getAllocationsByCharge)', () async {
      await insertCharge('c1', 's1', 'TUITION', expected: 100000, paid: 0);
      await dao.recordPayment(
        payment: const PaymentLocalModel(
          id: 'pay1',
          clientUuid: 'pay1',
          studentId: 's1',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'Ada',
          payerLastName: 'Lovelace',
          payerMiddleName: 'B',
          payerPhoneNumber: '+243816939060',
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
        outboxEntryId: 'ob-pay',
        nowMs: 1000,
      );

      final byPayment = (await dao.getAllocationsByPayment('pay1')).single;
      final byCharge = (await dao.getAllocationsByCharge('c1')).single;
      for (final a in [byPayment, byCharge]) {
        expect(a.payerFirstName, 'Ada');
        expect(a.payerLastName, 'Lovelace');
        expect(a.payerMiddleName, 'B');
        // Le NUMÉRO est replié par les deux lectures, ou par aucune : la table
        // des imputations d'un frais et celle d'un versement montrent la même
        // personne, elles doivent pouvoir la rappeler pareil.
        expect(a.payerPhoneNumber, '+243816939060');
        expect(a.paidAt, '2026-07-06T10:00:00Z');
      }
    });

    /// Une imputation d'un versement antérieur au palier v28 : le repli rend
    /// `null`, jamais une chaîne vide — l'UI doit pouvoir distinguer « pas de
    /// numéro » d'un numéro effacé.
    test(
      'imputation sans numéro : le repli rend null, pas une chaîne vide',
      () async {
        await insertCharge('c2', 's1', 'TUITION', expected: 100000, paid: 0);
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'pay2',
            clientUuid: 'pay2',
            studentId: 's1',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'Ada',
            payerLastName: 'Lovelace',
          ),
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a2',
              clientUuid: 'a2',
              paymentId: 'pay2',
              studentChargeId: 'c2',
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
          outboxEntryId: 'ob-pay2',
          nowMs: 1000,
        );

        expect(
          (await dao.getAllocationsByCharge('c2')).single.payerPhoneNumber,
          isNull,
        );
      },
    );
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
