import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

import '../../offline_full_db.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late Database db;
  late FinanceOfflineRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    final syncEngine = MockSyncEngine();
    when(
      () => syncEngine.flush(),
    ).thenAnswer((_) async => const SyncFlushReport());
    repo = FinanceOfflineRepositoryImpl(
      dao: FinanceLocalDao(db, const IdGenerator(Uuid())),
      idGenerator: const IdGenerator(Uuid()),
      syncEngine: syncEngine,
      now: () => 1000,
    );
  });

  tearDown(() async => db.close());

  test('recordPayment : total ≠ Σ allocations → ValidationFailure, rien écrit '
      '(fail-fast, pas de 422 qui immobilise l\'argent)', () async {
    final result = await repo.recordPayment(
      RecordPaymentDraft(
        studentId: 's1',
        academicYearId: 'ay-1',
        paidAt: '2026-07-06T10:00:00Z',
        payerFirstName: 'S',
        payerLastName: 'M',
        // ≠ Σ allocations (30000)
        amounts: MoneyBag.of(const [Money(50000, 'USD')]),
        allocations: [
          const AllocationDraft(
            feeCode: 'TUITION',
            studentChargeLabel: 'Scolarité',
            amountInCents: 30000,
            currency: 'USD',
          ),
        ],
      ),
    );

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('!'));
    expect(await db.query('payments'), isEmpty, reason: 'aucune écriture');
    expect(await db.query('outbox'), isEmpty);
  });

  test(
    'recordPayment : total juste GLOBALEMENT mais mal réparti → refus',
    () async {
      // 3 000 déclarés d'un côté, 3 000 imputés de l'autre : la comparaison
      // scalaire d'avant laissait passer. Le serveur, lui, vérifie désormais
      // `ALLOCATION_SUM_MISMATCH` DEVISE PAR DEVISE — le 422 tomberait sur de
      // l'argent physiquement reçu, reçu déjà imprimé, et l'immobiliserait en
      // SYNC_ERROR.
      final result = await repo.recordPayment(
        RecordPaymentDraft(
          studentId: 's1',
          academicYearId: 'ay-1',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'S',
          payerLastName: 'M',
          amounts: MoneyBag.of(const [Money(300000, 'USD')]),
          allocations: [
            const AllocationDraft(
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 100000,
              currency: 'USD',
            ),
            const AllocationDraft(
              feeCode: 'INSURANCE',
              studentChargeLabel: 'Assurance',
              amountInCents: 200000,
              currency: 'CDF',
            ),
          ],
        ),
      );

      expect(result.isLeft(), isTrue);
      // C'est bien le FAIL-FAST DE RÉPARTITION qui a mordu, et pas la garde
      // anti-mixte qui le suit : sans cette vérification, un fail-fast redevenu
      // scalaire passerait au vert, couvert par la seconde garde.
      result.fold((f) {
        expect(f, isA<ValidationFailure>());
        expect(f.message, contains('somme des allocations'));
      }, (_) => fail('!'));
      expect(await db.query('payments'), isEmpty, reason: 'aucune écriture');
      expect(await db.query('outbox'), isEmpty);
    },
  );

  test(
    'recordPayment : deux devises dans un même versement → ACCEPTÉ',
    () async {
      // TEST RETOURNÉ. La garde qui refusait ce cas a tenu la place le temps que
      // le contrat porte `amounts[]` — « pas encore », jamais « jamais ».
      //
      // Un passage au guichet qui solde une créance en dollars et une en francs
      // est un ACTE : un versement, un reçu, une notification. Imposer deux
      // gestes au caissier serait laisser le schéma dicter le métier.
      final result = await repo.recordPayment(
        const RecordPaymentDraft(
          studentId: 's1',
          academicYearId: 'ay-1',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'S',
          payerLastName: 'M',
          allocations: [
            AllocationDraft(
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 42500,
              currency: 'USD',
            ),
            AllocationDraft(
              feeCode: 'INSURANCE',
              studentChargeLabel: 'Assurance',
              amountInCents: 9000000,
              currency: 'CDF',
            ),
          ],
        ),
      );

      expect(result.isRight(), isTrue);
      // UN versement, et ses deux imputations — chacune dans sa devise.
      expect(await db.query('payments'), hasLength(1));
      final allocations = await db.query(
        'payment_allocations',
        orderBy: 'currency',
      );
      expect(allocations, hasLength(2));
      expect(allocations.first['currency'], 'CDF');
      expect(allocations.last['currency'], 'USD');
      // UNE entrée d'outbox : un acte, un envoi.
      expect(await db.query('outbox'), hasLength(1));
    },
  );

  test(
    'recordPayment : la devise vient des IMPUTATIONS, pas du brouillon',
    () async {
      // C'est `allocation.currency == charge.currency` que le serveur vérifie ;
      // la devise du brouillon n'est qu'une déclaration d'intention.
      final result = await repo.recordPayment(
        const RecordPaymentDraft(
          studentId: 's1',
          academicYearId: 'ay-1',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'S',
          payerLastName: 'M',
          allocations: [
            AllocationDraft(
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 30000,
              currency: 'CDF',
            ),
          ],
        ),
      );

      expect(result.isRight(), isTrue);
      // Le versement ne porte plus de devise : elle vit sur ses imputations, où
      // le serveur la vérifie (`allocation.currency == charge.currency`).
      expect((await db.query('payment_allocations')).single['currency'], 'CDF');
    },
  );

  test(
    'recordPayment : total cohérent → Right(paymentId) + paiement en file',
    () async {
      final result = await repo.recordPayment(
        const RecordPaymentDraft(
          studentId: 's1',
          academicYearId: 'ay-1',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'S',
          payerLastName: 'M',
          allocations: [
            AllocationDraft(
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
        ),
      );

      expect(result.isRight(), isTrue);
      // Le montant vit sur les imputations : `payments` n'en porte plus.
      expect(
        (await db.query('payment_allocations')).single['amount_in_cents'],
        30000,
      );
      // RC provisoire toujours émis à l'encaissement (FRONT §7).
      expect((await db.query('generated_documents')).single['doc_type'], 'RC');
      expect((await db.query('outbox')).single['aggregate_type'], 'PAYMENT');
    },
  );

  /// Le numéro du payeur doit atteindre LES DEUX destinations d'un même geste :
  /// la ligne locale (qui alimente l'annuaire du prochain versement) ET le
  /// payload d'outbox (qui le porte au serveur). N'en tenir qu'une donnerait un
  /// écran qui propose un numéro que le serveur n'a jamais reçu, ou l'inverse —
  /// et le versement est append-only : rien ne se corrige après coup.
  test('recordPayment : le téléphone du payeur atteint la ligne locale ET '
      'la file d\'attente', () async {
    final result = await repo.recordPayment(
      const RecordPaymentDraft(
        studentId: 's1',
        academicYearId: 'ay-1',
        paidAt: '2026-07-06T10:00:00Z',
        payerFirstName: 'Joseph',
        payerLastName: 'Kabongo',
        payerPhoneNumber: '+243816939060',
        allocations: [
          AllocationDraft(
            feeCode: 'TUITION',
            studentChargeLabel: 'Scolarité',
            amountInCents: 30000,
            currency: 'USD',
          ),
        ],
      ),
    );

    expect(result.isRight(), isTrue);
    expect(
      (await db.query('payments')).single['payer_phone_number'],
      '+243816939060',
    );

    final payload =
        jsonDecode((await db.query('outbox')).single['payload'] as String)
            as Map<String, dynamic>;
    expect(
      (payload['payment'] as Map<String, dynamic>)['payerPhoneNumber'],
      '+243816939060',
    );
  });

  /// La ligne de grille payée doit atteindre LES DEUX destinations du même
  /// geste : la colonne locale — c'est elle que lira la reprise des versements
  /// bloqués — ET le payload d'outbox, qui la porte au serveur.
  ///
  /// N'en tenir qu'une, c'est retomber sur la nature du frais, que le serveur
  /// refuse d'arbitrer dès qu'un niveau porte deux tranches d'un même minerval.
  /// Et le versement est append-only : rien ne se corrige après coup.
  test('recordPayment : la ligne de grille atteint la colonne locale ET '
      'la file d\'attente', () async {
    final result = await repo.recordPayment(
      const RecordPaymentDraft(
        studentId: 's1',
        academicYearId: 'ay-1',
        paidAt: '2026-07-06T10:00:00Z',
        payerFirstName: 'Joseph',
        payerLastName: 'Kabongo',
        allocations: [
          AllocationDraft(
            feeTariffId: '1d763648-70e0-4272-8ca1-224db48adfd1',
            feeCode: 'EXAMINATION',
            studentChargeLabel: 'Organisation matériel examens — 2/3',
            amountInCents: 500000,
            currency: 'CDF',
          ),
        ],
      ),
    );

    expect(result.isRight(), isTrue);
    expect(
      (await db.query('payment_allocations')).single['fee_tariff_id'],
      '1d763648-70e0-4272-8ca1-224db48adfd1',
    );

    final payload =
        jsonDecode((await db.query('outbox')).single['payload'] as String)
            as Map<String, dynamic>;
    final alloc =
        (payload['allocations'] as List<dynamic>).single
            as Map<String, dynamic>;
    expect(alloc['feeTariffId'], '1d763648-70e0-4272-8ca1-224db48adfd1');
    // La nature part avec : le serveur ne verrouille comme candidates que les
    // créances portant les `feeCode` du payload — un tarif seul ne trouverait
    // rien et retomberait sur le refus qu'on cherche à éviter.
    expect(alloc['feeCode'], 'EXAMINATION');
  });

  /// Un versement mis en file par une version ANTÉRIEURE de l'app n'a pas de
  /// numéro. Le refuser ici bloquerait définitivement de l'argent déjà
  /// encaissé, reçu déjà imprimé : la colonne et le contrat restent nullables.
  test(
    'recordPayment : sans téléphone, l\'encaissement passe quand même',
    () async {
      final result = await repo.recordPayment(
        const RecordPaymentDraft(
          studentId: 's1',
          academicYearId: 'ay-1',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'Joseph',
          payerLastName: 'Kabongo',
          allocations: [
            AllocationDraft(
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
        ),
      );

      expect(result.isRight(), isTrue);
      expect((await db.query('payments')).single['payer_phone_number'], isNull);
    },
  );
}
