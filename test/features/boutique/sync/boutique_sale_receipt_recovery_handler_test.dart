import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_receipt_recovery_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_receipt_recovery_handler.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_receipt_repository.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

const _saleId = 'vente-1';

OutboxEntry _entry({String payload = '{"saleId":"$_saleId"}'}) => OutboxEntry(
  id: BoutiqueReceiptRecoveryDao.entryIdOf(_saleId),
  aggregateType: BoutiqueReceiptRecoveryDao.aggregateType,
  aggregateId: _saleId,
  operation: OutboxOperation.create,
  payload: payload,
  schoolId: 'E1',
  createdAt: 0,
);

EditiqueDocument _document({String? number = 'ETL-RV-2526-000413'}) =>
    EditiqueDocument(
      type: EditiqueDocumentType.saleReceipt,
      bytes: Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]),
      fileName: 'recu.pdf',
      documentNumber: number,
    );

/// La réclamation automatique du reçu de vente qu'un accusé n'a pas rapporté :
/// sans elle, le ticket — qui n'imprime qu'avec le numéro — attendrait pour
/// toujours.
void main() {
  late Database db;
  late _FakeReceipts receipts;

  setUp(() async {
    db = await openFullOfflineDb();
    receipts = _FakeReceipts();
  });
  tearDown(() async => db.close());

  Future<void> seedSale({String? number}) => db.insert(
    'boutique_sales',
    BoutiqueSaleLocalModel(
      id: _saleId,
      schoolId: 'E1',
      academicYearId: 'ay-1',
      soldAt: '2026-11-17T08:00:00Z',
      receiptNumber: number,
      syncStatus: 'SYNCED',
      updatedAt: 0,
    ).toMap(),
  );

  BoutiqueSaleReceiptRecoveryHandler handler({String schoolId = 'E1'}) =>
      BoutiqueSaleReceiptRecoveryHandler(
        receipts: () => receipts,
        dao: BoutiqueReceiptRecoveryDao(db),
        currentUser: CurrentUserContext()..set('u1', schoolId: schoolId),
      );

  test('la marque naît UNE fois par vente, avec son école', () async {
    await seedSale();

    await BoutiqueReceiptRecoveryDao.markMissingIn(
      db,
      saleId: _saleId,
      nowMs: 1,
    );
    await BoutiqueReceiptRecoveryDao.markMissingIn(
      db,
      saleId: _saleId,
      nowMs: 2,
    );

    final marks = await db.query('outbox');
    expect(marks, hasLength(1));
    expect(marks.single['school_id'], 'E1');
    expect(
      marks.single['aggregate_type'],
      BoutiqueReceiptRecoveryDao.aggregateType,
    );
  });

  test('le reçu réclamé avec son numéro acquitte la marque', () async {
    await seedSale();
    receipts.result = Right(_document());

    final result = await handler().dispatch(_entry());

    expect(result.outcome, OutboxDispatchOutcome.acked);
    expect(receipts.claimed, [_saleId]);
  });

  test('un reçu rendu SANS numéro se réclame encore', () async {
    await seedSale();
    receipts.result = Right(_document(number: null));

    final result = await handler().dispatch(_entry());

    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('un numéro déjà là (pull, geste manuel) : rien à réclamer', () async {
    await seedSale(number: 'ETL-RV-2526-000413');

    final result = await handler().dispatch(_entry());

    expect(result.outcome, OutboxDispatchOutcome.acked);
    expect(receipts.claimed, isEmpty);
  });

  test('une vente qui a quitté le poste : rien à réclamer', () async {
    final result = await handler().dispatch(_entry());

    expect(result.outcome, OutboxDispatchOutcome.acked);
    expect(receipts.claimed, isEmpty);
  });

  test('le réseau manque : on réessaie', () async {
    await seedSale();
    receipts.result = const Left(NetworkFailure('hors ligne'));

    final result = await handler().dispatch(_entry());

    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('une vente inconnue du serveur : échec visible', () async {
    await seedSale();
    receipts.result = const Left(NotFoundFailure('vente introuvable'));

    final result = await handler().dispatch(_entry());

    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('un payload illisible ne se rejoue pas', () async {
    final result = await handler().dispatch(_entry(payload: '{'));

    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('une marque d\'une autre école n\'est pas réclamée ici', () async {
    await seedSale();

    final result = await handler(schoolId: 'E2').dispatch(_entry());

    expect(result.outcome, isNot(OutboxDispatchOutcome.acked));
    expect(receipts.claimed, isEmpty);
  });
}

class _FakeReceipts implements BoutiqueReceiptRepository {
  Either<Failure, EditiqueDocument> result = const Left(
    ServerFailure('non configuré'),
  );
  final List<String> claimed = [];

  @override
  Future<Either<Failure, EditiqueDocument>> claimSaleReceipt(
    String saleId,
  ) async {
    claimed.add(saleId);
    return result;
  }
}
