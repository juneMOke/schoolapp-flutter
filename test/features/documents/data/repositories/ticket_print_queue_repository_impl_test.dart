import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/ticket_print_queue_dao.dart';
import 'package:school_app_flutter/features/documents/data/repositories/ticket_print_queue_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_correction_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/receipt_recovery_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_error_codes.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_composer.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/payment_correction_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../offline_full_db.dart';

class _MockSyncEngine extends Mock implements SyncEngine {}

/// Le reçu de chaque versement, réglé par test : scellé (numéro définitif) ou
/// pas encore.
class _Receipts implements PaymentReceiptResolver {
  final Map<String, String> sealed = {};

  @override
  Future<PaymentReceiptReference> resolve(String paymentId) async {
    final number = sealed[paymentId];
    return number == null
        ? const PaymentReceiptReference(
            number: 'PROV-0001',
            status: PaymentReceiptStatus.provisional,
          )
        : PaymentReceiptReference(
            number: number,
            status: PaymentReceiptStatus.definitive,
            documentId: 'doc-$paymentId',
          );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// La file des tickets (continuité RC, lots B et D), exercée sur une vraie base
/// et par les vrais gestes : encaisser, annuler, corriger.
void main() {
  late Database db;
  late FinanceOfflineRepositoryImpl cashier;
  late PaymentCorrectionRepositoryImpl corrections;
  late _Receipts receipts;
  late TicketPrintQueueRepositoryImpl queue;
  late int flushes;

  setUp(() async {
    flushes = 0;
    db = await openFullOfflineDb();
    final sync = _MockSyncEngine();
    when(() => sync.flush()).thenAnswer((_) async => const SyncFlushReport());
    const ids = IdGenerator(Uuid());
    final user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    cashier = FinanceOfflineRepositoryImpl(
      dao: FinanceLocalDao(db, ids),
      idGenerator: ids,
      syncEngine: sync,
      currentUser: user,
      now: () => 1000,
    );
    corrections = PaymentCorrectionRepositoryImpl(
      dao: PaymentCorrectionWriteDao(db, FinancePaymentWriteDao(db)),
      composer: PaymentComposer(idGenerator: ids, currentUser: user),
      idGenerator: ids,
      syncEngine: sync,
      currentUser: user,
      now: () => 2000,
    );
    receipts = _Receipts();
    queue = TicketPrintQueueRepositoryImpl(
      queue: TicketPrintQueueDao(db),
      tickets: ProvisionalTicketDao(db),
      receipts: receipts,
      recoveries: ReceiptRecoveryDao(db),
      flush: () async => flushes++,
      now: () => DateTime.fromMillisecondsSinceEpoch(5000),
    );

    await db.insert('students', {
      'id': 's-1',
      'first_name': 'Marie',
      'last_name': 'Tshiala',
      'gender': 'F',
      'date_of_birth': '2015-01-01',
    });
    await db.insert('student_charges', {
      'id': 'c-1',
      'student_id': 's-1',
      'academic_year_id': 'ay-1',
      'fee_code': 'MINERVAL',
      'label': 'Minerval',
      'expected_amount_in_cents': 15000,
      'currency': 'USD',
    });
  });

  tearDown(() async => db.close());

  RecordPaymentDraft draftOf(int cents) => RecordPaymentDraft(
    studentId: 's-1',
    academicYearId: 'ay-1',
    paidAt: '2026-09-25T13:11:41Z',
    payerFirstName: 'Marie',
    payerLastName: 'Tshiala',
    allocations: [
      AllocationDraft(
        studentChargeId: 'c-1',
        feeCode: 'MINERVAL',
        studentChargeLabel: 'Minerval',
        amountInCents: cents,
        currency: 'USD',
      ),
    ],
  );

  Future<String> collect(int cents) async => (await cashier.recordPayment(
    draftOf(cents),
  )).getOrElse(() => throw StateError('encaissement refusé'));

  Future<List<TicketPrintJob>> jobs() async => (await queue.pendingJobs())
      .getOrElse(() => throw StateError('illisible'));

  /// Ce que l'accusé d'une correction écrit (cf. `PaymentCorrectionSyncDao`).
  Future<void> acknowledge(String correctionId, String paymentId) async {
    await db.update(
      'payment_corrections',
      {'status': PaymentCorrectionStatus.applied.dbValue},
      where: 'id = ?',
      whereArgs: [correctionId],
    );
    await db.update(
      'payments',
      {'cancelled_at': 3000},
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  group('le ticket de caisse', () {
    test('est dû dès l encaissement, et attend son numéro', () async {
      final payment = await collect(15000);

      final job = (await jobs()).single;
      expect(job.paymentId, payment);
      expect(job.kind, TicketPrintJobKind.receipt);
      expect(job.state, TicketPrintJobState.awaitingNumber);
      expect(job.receiptNumber, isNull);
      expect(job.studentFullName, contains('Tshiala'));
    });

    test(
      'devient prêt quand le reçu est scellé, d ou que vienne le numéro',
      () async {
        final payment = await collect(15000);
        receipts.sealed[payment] = 'CF-RC-2627-000802';

        final job = (await jobs()).single;
        expect(job.state, TicketPrintJobState.ready);
        expect(job.receiptNumber, 'CF-RC-2627-000802');
      },
    );

    test('sort de la file une fois imprimé, et le versement le sait', () async {
      final payment = await collect(15000);
      receipts.sealed[payment] = 'CF-RC-2627-000802';

      await queue.markPrinted((await jobs()).single);

      expect(await jobs(), isEmpty);
      final row = (await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: [payment],
      )).single;
      expect(row['ticket_printed_at'], 5000);
    });

    test('sort aussi s il a été imprimé depuis l écran de succès', () async {
      final payment = await collect(15000);
      await ProvisionalTicketDao(
        db,
      ).markTicketPrinted(payment, DateTime.fromMillisecondsSinceEpoch(4000));

      expect(await jobs(), isEmpty);
    });

    test('un versement descendu d un autre poste n y entre jamais', () async {
      await db.insert('payments', {
        'id': 'p-ailleurs',
        'client_uuid': 'p-ailleurs',
        'student_id': 's-1',
        'academic_year_id': 'ay-1',
        'method': 'CASH',
        'paid_at': '2026-09-25T13:11:41Z',
        'sync_status': 'SYNCED',
        'updated_at': 1000,
      });

      expect(await jobs(), isEmpty);
    });

    test('numéroté mais élève inconnu ici : il attend l élève', () async {
      final payment = await collect(15000);
      receipts.sealed[payment] = 'CF-RC-2627-000802';
      await db.delete('students');

      expect((await jobs()).single.state, TicketPrintJobState.awaitingStudent);
    });

    // Retour du back du 2026-10-28 : un accusé peut revenir sans reçu.
    test(
      'accusé sans reçu : il le dit, puis devient prêt au rattrapage',
      () async {
        final payment = await collect(15000);
        await ReceiptRecoveryDao.markMissingIn(
          db,
          paymentId: payment,
          nowMs: 3000,
        );

        expect((await jobs()).single.state, TicketPrintJobState.receiptMissing);

        // Le rattrapage a abouti : l'entrée d'outbox est acquittée puis purgée.
        await db.delete(
          'outbox',
          where: 'aggregate_type = ?',
          whereArgs: [ReceiptRecoveryDao.aggregateType],
        );
        receipts.sealed[payment] = 'CF-RC-2627-000802';

        expect((await jobs()).single.state, TicketPrintJobState.ready);
      },
    );

    test('Relancer remet le rattrapage en tête et lance le flush', () async {
      final payment = await collect(15000);
      await ReceiptRecoveryDao.markMissingIn(
        db,
        paymentId: payment,
        nowMs: 3000,
      );
      await db.update(
        'outbox',
        {'status': 'SYNC_ERROR', 'attempts': 4, 'next_attempt_at': 99999},
        where: 'aggregate_type = ?',
        whereArgs: [ReceiptRecoveryDao.aggregateType],
      );

      final result = await queue.retryReceipt((await jobs()).single);

      expect(result.isRight(), isTrue);
      expect(flushes, 1);
      final entry = (await db.query(
        'outbox',
        where: 'aggregate_type = ?',
        whereArgs: [ReceiptRecoveryDao.aggregateType],
      )).single;
      expect(entry['status'], 'PENDING');
      expect(entry['attempts'], 0);
      expect(entry['next_attempt_at'], 0);
    });

    test('garde la trace d un échec, et reste dans la file', () async {
      final payment = await collect(15000);
      receipts.sealed[payment] = 'CF-RC-2627-000802';

      await queue.recordProblem((await jobs()).single, 'unreachable');

      expect((await jobs()).single.lastProblem, 'unreachable');
    });
  });

  group('l annulation', () {
    PaymentCorrectionDraft cancelOf(String id) => PaymentCorrectionDraft(
      paymentId: id,
      reason: PaymentCorrectionReason.refunded,
    );

    test('remplace le ticket de caisse par son ticket d annulation', () async {
      final payment = await collect(15000);
      receipts.sealed[payment] = 'CF-RC-2627-000802';

      await corrections.correctPayment(cancelOf(payment));

      final job = (await jobs()).single;
      expect(job.kind, TicketPrintJobKind.cancellation);
      // Pas encore acquittée : le ticket dirait une annulation qui n'a pas eu
      // lieu.
      expect(job.state, TicketPrintJobState.awaitingNumber);
    });

    test('est prête une fois acquittée', () async {
      final payment = await collect(15000);
      receipts.sealed[payment] = 'CF-RC-2627-000802';
      final outcome = (await corrections.correctPayment(
        cancelOf(payment),
      )).getOrElse(() => throw StateError('refusé'));

      await acknowledge(outcome.correctionId, payment);

      final job = (await jobs()).single;
      expect(job.kind, TicketPrintJobKind.cancellation);
      expect(job.state, TicketPrintJobState.ready);
      expect(job.receiptNumber, 'CF-RC-2627-000802');
    });

    test(
      'refusée par le serveur, elle rend sa place au ticket de caisse',
      () async {
        final payment = await collect(15000);
        receipts.sealed[payment] = 'CF-RC-2627-000802';
        final outcome = (await corrections.correctPayment(
          cancelOf(payment),
        )).getOrElse(() => throw StateError('refusé'));

        await db.update(
          'payment_corrections',
          {'status': PaymentCorrectionStatus.rejected.dbValue},
          where: 'id = ?',
          whereArgs: [outcome.correctionId],
        );

        final job = (await jobs()).single;
        expect(job.kind, TicketPrintJobKind.receipt);
        expect(job.state, TicketPrintJobState.ready);
      },
    );

    // La revue l'a trouvé : un accusé perdu laisse la correction en attente,
    // mais le pull descend l'annulation. Le serveur fait foi.
    test('annulation descendue par le pull, accusé perdu : prête', () async {
      final payment = await collect(15000);
      receipts.sealed[payment] = 'CF-RC-2627-000802';
      await corrections.correctPayment(cancelOf(payment));

      await db.update(
        'payments',
        {'cancelled_at': 3000},
        where: 'id = ?',
        whereArgs: [payment],
      );

      final job = (await jobs()).single;
      expect(job.kind, TicketPrintJobKind.cancellation);
      expect(job.state, TicketPrintJobState.ready);
    });

    // Retour du back du 2026-10-28 : c'est le refus qui bloque le ticket, pas
    // la date — elle ne sert qu'à l'affichage.
    test('déjà corrigé ailleurs, même sans date : plus de ticket', () async {
      final payment = await collect(15000);
      receipts.sealed[payment] = 'CF-RC-2627-000802';
      final outcome = (await corrections.correctPayment(
        cancelOf(payment),
      )).getOrElse(() => throw StateError('refusé'));

      await db.update(
        'payment_corrections',
        {
          'status': PaymentCorrectionStatus.rejected.dbValue,
          'sync_error_code': FinanceErrorCodes.paymentAlreadyCorrected,
        },
        where: 'id = ?',
        whereArgs: [outcome.correctionId],
      );

      expect(await jobs(), isEmpty);
    });

    test('un ticket déjà sorti a quand même son ticket d annulation', () async {
      final payment = await collect(15000);
      receipts.sealed[payment] = 'CF-RC-2627-000802';
      await queue.markPrinted((await jobs()).single);

      await corrections.correctPayment(cancelOf(payment));

      expect((await jobs()).single.kind, TicketPrintJobKind.cancellation);
    });
  });

  group('la correction', () {
    PaymentCorrectionDraft replaceOf(String id) => PaymentCorrectionDraft(
      paymentId: id,
      reason: PaymentCorrectionReason.wrongAmount,
      replacement: draftOf(5000),
    );

    test('ticket d origine déjà sorti : seul le remplaçant est dû', () async {
      final origin = await collect(15000);
      receipts.sealed[origin] = 'CF-RC-2627-000802';
      await queue.markPrinted((await jobs()).single);

      final outcome = (await corrections.correctPayment(
        replaceOf(origin),
      )).getOrElse(() => throw StateError('refusé'));

      final job = (await jobs()).single;
      expect(job.kind, TicketPrintJobKind.receipt);
      expect(job.paymentId, outcome.replacementPaymentId);
    });

    test('ticket d origine sorti par l ancien chemin : rien de plus', () async {
      final origin = await collect(15000);
      receipts.sealed[origin] = 'CF-RC-2627-000802';
      // L'écran de succès ou le détail : seule la trace du versement est posée.
      await ProvisionalTicketDao(
        db,
      ).markTicketPrinted(origin, DateTime.fromMillisecondsSinceEpoch(4000));

      final outcome = (await corrections.correctPayment(
        replaceOf(origin),
      )).getOrElse(() => throw StateError('refusé'));

      final job = (await jobs()).single;
      expect(job.kind, TicketPrintJobKind.receipt);
      expect(job.paymentId, outcome.replacementPaymentId);
    });

    test(
      'ticket d origine jamais sorti : son numéro garde un papier',
      () async {
        final origin = await collect(15000);
        receipts.sealed[origin] = 'CF-RC-2627-000802';

        final outcome = (await corrections.correctPayment(
          replaceOf(origin),
        )).getOrElse(() => throw StateError('refusé'));

        final kinds = {for (final job in await jobs()) job.paymentId: job.kind};
        expect(kinds, {
          origin: TicketPrintJobKind.cancellation,
          outcome.replacementPaymentId: TicketPrintJobKind.receipt,
        });
      },
    );
  });

  test('les tickets prêts passent devant, dans l ordre des numéros', () async {
    final first = await collect(5000);
    final second = await collect(5000);
    final third = await collect(5000);
    receipts.sealed[second] = 'CF-RC-2627-000810';
    receipts.sealed[first] = 'CF-RC-2627-000811';

    expect(
      [for (final job in await jobs()) job.paymentId],
      [second, first, third],
    );
  });
}
