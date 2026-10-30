import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_ack_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/receipt_recovery_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_error_codes.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_receipt_recovery_outbox_handler.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

/// L'émission du reçu, réglée par test.
class _Editique implements EditiqueRepository {
  Either<Failure, EditiqueDocument> result = Right(
    EditiqueDocument(
      type: EditiqueDocumentType.paymentReceipt,
      bytes: Uint8List(0),
      fileName: 'CF-RC-2627-000802.pdf',
      documentNumber: 'CF-RC-2627-000802',
      documentId: 'doc-1',
    ),
  );
  final List<String> asked = [];

  @override
  Future<Either<Failure, EditiqueDocument>> emitPaymentReceipt({
    required String paymentId,
    String? studentId,
    String? academicYearId,
  }) async {
    asked.add(paymentId);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Le reçu qu'un accusé n'a pas rapporté (continuité des tickets RC, retour
/// du back du 2026-10-28) : marqué à l'accusé, rattrapé par l'outbox.
void main() {
  late Database db;
  late _Editique editique;
  late CurrentUserContext user;
  late PaymentReceiptRecoveryOutboxHandler handler;

  setUp(() async {
    db = await openFullOfflineDb();
    editique = _Editique();
    user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    handler = PaymentReceiptRecoveryOutboxHandler(
      editique: () => editique,
      dao: ReceiptRecoveryDao(db),
      currentUser: user,
    );
    await db.insert('payments', {
      'id': 'pay1',
      'client_uuid': 'pay1',
      'student_id': 's-1',
      'academic_year_id': 'ay-1',
      'method': 'CASH',
      'paid_at': '2026-10-28T09:00:00Z',
      'sync_status': 'PENDING_SYNC',
      'updated_at': 1000,
    });
    await db.insert('generated_documents', {
      'id': 'gd-1',
      'doc_domain': 'PAYMENT',
      'payment_id': 'pay1',
      'doc_type': 'RC',
      'number': 'PROV-0001',
      'status': 'PROVISIONAL',
    });
    // L'écriture que l'accusé acquitte : elle porte l'école.
    await db.insert('outbox', {
      'id': 'e-pay1',
      'aggregate_type': 'PAYMENT',
      'aggregate_id': 'pay1',
      'operation': 'CREATE',
      'payload': '{}',
      'school_id': 'school-1',
      'status': 'PENDING',
      'created_at': 1000,
    });
  });

  tearDown(() => db.close());

  Future<List<Map<String, Object?>>> recoveries() => db.query(
    'outbox',
    where: 'aggregate_type = ?',
    whereArgs: [ReceiptRecoveryDao.aggregateType],
  );

  Future<void> ack({String? receiptId}) =>
      FinancePaymentAckDao(db).applyPaymentAck(
        PaymentAggregateResponse(
          payment: AckPaymentRef(id: 'pay1', receiptId: receiptId),
        ),
        nowMs: 2000,
      );

  OutboxEntry entryOf(Map<String, Object?> row) => OutboxEntry.fromMap(row);

  group("l'accusé", () {
    test('sans reçu : le marque à récupérer, sous son école', () async {
      await ack();

      final row = (await recoveries()).single;
      expect(row['aggregate_id'], 'pay1');
      expect(row['school_id'], 'school-1');
      expect(jsonDecode(row['payload']! as String), {'paymentId': 'pay1'});
    });

    test(
      'rejoué : ne marque pas deux fois, ne remet pas le backoff à zéro',
      () async {
        await ack();
        await db.update(
          'outbox',
          {'attempts': 3},
          where: 'aggregate_type = ?',
          whereArgs: [ReceiptRecoveryDao.aggregateType],
        );

        await ack();

        final row = (await recoveries()).single;
        expect(row['attempts'], 3);
      },
    );

    test('avec son reçu : rien à rattraper', () async {
      await ack(receiptId: 'doc-1');

      expect(await recoveries(), isEmpty);
    });
  });

  group('le rattrapage', () {
    setUp(ack);

    test('reçu rendu : le versement porte son numéro définitif', () async {
      final result = await handler.dispatch(
        entryOf((await recoveries()).single),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(editique.asked, ['pay1']);
      final payment = (await db.query('payments')).single;
      expect(payment['receipt_id'], 'doc-1');
      final receipt = (await db.query('generated_documents')).single;
      expect(receipt['number'], 'CF-RC-2627-000802');
      expect(receipt['status'], 'DEFINITIVE');
      expect(receipt['emitted_on'], isNull);
    });

    test('reçu rendu avec son jour d émission : il est gardé', () async {
      editique.result = Right(
        EditiqueDocument(
          type: EditiqueDocumentType.paymentReceipt,
          bytes: Uint8List(0),
          fileName: 'CF-RC-2627-000802.pdf',
          documentNumber: 'CF-RC-2627-000802',
          documentId: 'doc-1',
          emittedOn: '2026-10-28',
        ),
      );

      await handler.dispatch(entryOf((await recoveries()).single));

      final receipt = (await db.query('generated_documents')).single;
      expect(receipt['emitted_on'], '2026-10-28');
    });

    test('versement annulé entre-temps : la marque tombe', () async {
      editique.result = const Left(
        ApiValidationFailure(
          code: ApiErrorCode.businessRule,
          detailCode: FinanceErrorCodes.paymentCancelled,
        ),
      );

      final result = await handler.dispatch(
        entryOf((await recoveries()).single),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(
        (await db.query('generated_documents')).single['status'],
        'PROVISIONAL',
      );
    });

    for (final (name, failure) in [
      ('réseau', const NetworkFailure()),
      ('5xx', const ServerFailure()),
      ('409 avant la release back', const ConflictFailure('conflit')),
      ('issue inconnue', const UncertainOutcomeFailure('?')),
      ('401', const InvalidCredentialsFailure('jeton')),
    ]) {
      test('$name : se rejoue, la route est idempotente', () async {
        editique.result = Left(failure);

        final result = await handler.dispatch(
          entryOf((await recoveries()).single),
        );

        expect(result.outcome, OutboxDispatchOutcome.retry);
      });
    }

    // Revue : la marque n'a pas d'auteur ; un 403 figé en SYNC_ERROR
    // interdirait à un collègue qui détient le droit de la reprendre.
    test('403 : se rejoue, un collègue autorisé la reprendra', () async {
      editique.result = const Left(UnauthorizedFailure());

      final result = await handler.dispatch(
        entryOf((await recoveries()).single),
      );

      expect(result.outcome, OutboxDispatchOutcome.retry);
    });

    test('un autre refus nommé : la marque reste visible', () async {
      editique.result = const Left(
        ApiValidationFailure(code: ApiErrorCode.validation),
      );

      final result = await handler.dispatch(
        entryOf((await recoveries()).single),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });

    // Revue : le numéro ne vit que dans `Content-Disposition`.
    test('reçu rendu sans numéro lisible : la marque reste', () async {
      editique.result = Right(
        EditiqueDocument(
          type: EditiqueDocumentType.paymentReceipt,
          bytes: Uint8List(0),
          fileName: 'recu.pdf',
          documentId: 'doc-1',
        ),
      );

      final result = await handler.dispatch(
        entryOf((await recoveries()).single),
      );

      expect(result.outcome, OutboxDispatchOutcome.retry);
      expect((await db.query('payments')).single['receipt_id'], 'doc-1');
    });

    Future<void> owesCancellation() => db.insert('ticket_print_jobs', {
      'id': 'j-cancel',
      'payment_id': 'pay1',
      'kind': 'cancellation',
      'created_at': 3000,
    });

    test(
      'annulé sans reçu jamais scellé : plus de ticket d annulation',
      () async {
        await owesCancellation();
        editique.result = const Left(
          ApiValidationFailure(
            code: ApiErrorCode.businessRule,
            detailCode: FinanceErrorCodes.paymentCancelled,
          ),
        );

        await handler.dispatch(entryOf((await recoveries()).single));

        expect(await db.query('ticket_print_jobs'), isEmpty);
      },
    );

    test('annulé, numéro pourtant connu ici : le ticket reste dû', () async {
      await owesCancellation();
      await db.update('generated_documents', {
        'number': 'CF-RC-2627-000802',
        'status': 'DEFINITIVE',
      });
      editique.result = const Left(
        ApiValidationFailure(
          code: ApiErrorCode.businessRule,
          detailCode: FinanceErrorCodes.paymentCancelled,
        ),
      );

      await handler.dispatch(entryOf((await recoveries()).single));

      expect(await db.query('ticket_print_jobs'), hasLength(1));
    });

    test('Relancer ne touche pas une marque acquittée', () async {
      await db.update(
        'outbox',
        {'status': 'ACKED'},
        where: 'aggregate_type = ?',
        whereArgs: [ReceiptRecoveryDao.aggregateType],
      );

      expect(await ReceiptRecoveryDao(db).retryNow('pay1'), isFalse);
      expect((await recoveries()).single['status'], 'ACKED');
    });

    test("d'une autre école : attend sa session", () async {
      user.set('u-1', schoolId: 'school-2');

      final result = await handler.dispatch(
        entryOf((await recoveries()).single),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      expect(editique.asked, isEmpty);
    });

    test('versement parti de ce poste : plus rien à attester', () async {
      await db.delete('payments');

      final result = await handler.dispatch(
        entryOf((await recoveries()).single),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(editique.asked, isEmpty);
    });
  });
}
