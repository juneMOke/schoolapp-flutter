import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_receipt_recovery_dao.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_write_dao.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_error_codes.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_outbox_handler.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_sync_models.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sync_api.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

class _MockApi extends Mock implements BoutiqueSyncApi {}

const _saleId = 'vente-1';
const _lineId = 'ligne-1';

BoutiqueSaleRequest _request({String? beneficiaryId}) => BoutiqueSaleRequest(
  sale: BoutiqueSaleInput(
    id: _saleId,
    academicYearId: 'ay-1',
    payerLastName: 'Ndombo',
    payerFirstName: 'Willy',
    amounts: MoneyBag.of(const [Money(1500, 'USD')]),
    soldAt: '2026-08-29T11:42:00Z',
  ),
  lines: [
    BoutiqueSaleLineInput(
      articleId: 'art-polo',
      beneficiaryStudentId: beneficiaryId,
      schoolLevelId: beneficiaryId == null ? 'lvl-1' : null,
      quantity: 1,
      unitPriceInCents: 1500,
      lineTotalInCents: 1500,
      currency: 'USD',
    ),
  ],
  authorId: 'u1',
);

OutboxEntry _entry(BoutiqueSaleRequest request) => OutboxEntry(
  id: 'outbox-1',
  aggregateType: BoutiqueSaleWriteDao.aggregateType,
  aggregateId: _saleId,
  operation: OutboxOperation.create,
  payload: _encode(request),
  schoolId: 'E1',
  createdAt: 0,
);

/// Le payload est du JSON : on passe par la MÊME sérialisation que la
/// production, pour que ce test échoue si la forme du fil change.
String _encode(BoutiqueSaleRequest request) => jsonEncode(request.toJson());

DioException _http(int status, {Map<String, dynamic>? body}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: body,
  ),
);

void main() {
  late Database db;
  late BoutiqueSaleWriteDao dao;
  late _MockApi api;

  setUpAll(() {
    registerFallbackValue(_request());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    db = await openFullOfflineDb();
    dao = BoutiqueSaleWriteDao(db);
    api = _MockApi();

    await dao.recordSale(
      sale: const BoutiqueSaleLocalModel(
        id: _saleId,
        schoolId: 'E1',
        academicYearId: 'ay-1',
        payerLastName: 'Ndombo',
        soldAt: '2026-08-29T11:42:00Z',
        updatedAt: 0,
      ),
      lines: const [
        BoutiqueSaleLineLocalModel(
          id: _lineId,
          saleId: _saleId,
          articleId: 'art-polo',
          articleLabel: 'Polo Lacoste',
          quantity: 1,
          unitPriceInCents: 1500,
          lineTotalInCents: 1500,
          currency: 'USD',
        ),
      ],
      request: _request(),
      outboxEntryId: 'outbox-1',
      schoolId: 'E1',
      nowMs: 0,
    );
  });

  tearDown(() async => db.close());

  BoutiqueSaleOutboxHandler handlerWith(
    OutboxDependencyState state, {
    int nowMs = 1000,
  }) => BoutiqueSaleOutboxHandler(
    api: api,
    dao: dao,
    dependency: (_, _) async => state,
    extras: const {},
    now: () => nowMs,
  );

  Future<Map<String, Object?>> saleRow() async => (await db.query(
    'boutique_sales',
    where: 'id = ?',
    whereArgs: [_saleId],
  )).single;

  group('garde de dépendance ENROLLMENT', () {
    test('inscription en vol → BLOCKED, jamais failed', () async {
      // Attente PROPRE : sans `attempts++`, sans backoff, sans faux
      // SYNC_ERROR sur de l'argent déjà reçu.
      final result = await handlerWith(
        OutboxDependencyState.waiting,
      ).dispatch(_entry(_request(beneficiaryId: 'elv-1')));

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.commitSale(any(), any()));
    });

    test('inscription en ÉCHEC → BLOCKED aussi, pas failed', () async {
      // `failed` serait un cul-de-sac : aucune entrée SYNC_ERROR ne se
      // re-pousse. `blocked` reste auto-cicatrisant — dès que l'inscription est
      // corrigée, la vente repart seule.
      final result = await handlerWith(
        OutboxDependencyState.parentFailed,
      ).dispatch(_entry(_request(beneficiaryId: 'elv-1')));

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test('une vente WALK-IN ne dépend de personne', () async {
      // Elle ne nomme aucun élève : la bloquer sur une inscription qu'elle ne
      // référence pas la retiendrait sans raison.
      when(
        () => api.commitSale(any(), any()),
      ).thenAnswer((_) async => const BoutiqueSaleResponse(saleId: _saleId));

      final result = await handlerWith(
        OutboxDependencyState.parentFailed,
      ).dispatch(_entry(_request()));

      expect(result.outcome, OutboxDispatchOutcome.acked);
    });
  });

  group('application de l\'ACK', () {
    test('un reçu scellé passe la vente SYNCED, avec son numéro', () async {
      when(() => api.commitSale(any(), any())).thenAnswer(
        (_) async => const BoutiqueSaleResponse(
          saleId: _saleId,
          receiptDocumentId: 'doc-1',
          documents: [
            SealedSaleDocument(
              type: 'SALE_RECEIPT',
              documentNumber: 'ETL-RV-2526-000413',
              status: 'DEFINITIVE',
            ),
          ],
        ),
      );

      final result = await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final row = await saleRow();
      expect(row['sync_status'], 'SYNCED');
      expect(row['receipt_document_id'], 'doc-1');
      expect(row['receipt_number'], 'ETL-RV-2526-000413');
    });

    test('l\'ACK pose la date d\'émission et le QR du reçu', () async {
      when(() => api.commitSale(any(), any())).thenAnswer(
        (_) async => BoutiqueSaleResponse.fromJson(const {
          'sale': {'id': _saleId, 'receiptDocumentId': 'doc-1'},
          'documents': [
            {
              'type': 'SALE_RECEIPT',
              'documentNumber': 'ETL-RV-2526-000413',
              'status': 'DEFINITIVE',
              'emittedAt': '2026-11-17T00:00:00Z',
              'verificationUrl': 'https://verify.eteeloconnect.com/d/abc',
            },
          ],
        }),
      );

      await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      final row = await saleRow();
      expect(row['receipt_emitted_on'], '2026-11-17');
      expect(
        row['receipt_verification_url'],
        'https://verify.eteeloconnect.com/d/abc',
      );
    });

    test('un ACK SANS document acquitte quand même la vente', () async {
      // Le scellement est best-effort et hors transaction : un échec
      // d'imprimerie laisse la vente enregistrée. La refuser ici la ferait
      // repousser en boucle alors que le serveur l'a déjà.
      when(
        () => api.commitSale(any(), any()),
      ).thenAnswer((_) async => const BoutiqueSaleResponse(saleId: _saleId));

      final result = await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final row = await saleRow();
      expect(row['sync_status'], 'SYNCED');
      expect(row['receipt_number'], isNull);
      // Le ticket attend le numéro : la marque le réclamera au prochain flush.
      final marks = await db.query(
        'outbox',
        where: 'aggregate_type = ?',
        whereArgs: [BoutiqueReceiptRecoveryDao.aggregateType],
      );
      expect(marks, hasLength(1));
      expect(marks.single['aggregate_id'], _saleId);
    });

    test('un ACK rejoué ne fait pas perdre ce qu\'un pull a posé', () async {
      // Le POST est parti, la réponse s'est perdue ; entre-temps le pull a
      // descendu la vente numérotée. Le rejeu rend un ACK plus pauvre.
      await db.update('boutique_sales', {
        'receipt_document_id': 'doc-1',
        'receipt_number': 'ETL-RV-2526-000413',
        'receipt_emitted_on': '2026-11-17',
        'receipt_verification_url': 'https://verify.eteeloconnect.com/d/abc',
      });
      when(() => api.commitSale(any(), any())).thenAnswer(
        (_) async => const BoutiqueSaleResponse(
          saleId: _saleId,
          receiptDocumentId: 'doc-1',
          documents: [
            SealedSaleDocument(
              type: 'SALE_RECEIPT',
              documentNumber: 'ETL-RV-2526-000413',
              status: 'DEFINITIVE',
            ),
          ],
        ),
      );

      await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      final row = await saleRow();
      expect(row['receipt_emitted_on'], '2026-11-17');
      expect(
        row['receipt_verification_url'],
        'https://verify.eteeloconnect.com/d/abc',
      );
    });

    test(
      'un ACK sans document garde le numéro déjà connu, sans marque',
      () async {
        await db.update('boutique_sales', {
          'receipt_document_id': 'doc-1',
          'receipt_number': 'ETL-RV-2526-000413',
        });
        when(
          () => api.commitSale(any(), any()),
        ).thenAnswer((_) async => const BoutiqueSaleResponse(saleId: _saleId));

        await handlerWith(
          OutboxDependencyState.ready,
        ).dispatch(_entry(_request()));

        final row = await saleRow();
        expect(row['receipt_document_id'], 'doc-1');
        expect(row['receipt_number'], 'ETL-RV-2526-000413');
        final marks = await db.query(
          'outbox',
          where: 'aggregate_type = ?',
          whereArgs: [BoutiqueReceiptRecoveryDao.aggregateType],
        );
        expect(marks, isEmpty);
      },
    );

    test('un ACK qui rapporte le numéro ne pose AUCUNE marque', () async {
      when(() => api.commitSale(any(), any())).thenAnswer(
        (_) async => const BoutiqueSaleResponse(
          saleId: _saleId,
          documents: [
            SealedSaleDocument(
              type: 'SALE_RECEIPT',
              documentNumber: 'ETL-RV-2526-000413',
              status: 'DEFINITIVE',
            ),
          ],
        ),
      );

      await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      final marks = await db.query(
        'outbox',
        where: 'aggregate_type = ?',
        whereArgs: [BoutiqueReceiptRecoveryDao.aggregateType],
      );
      expect(marks, isEmpty);
    });

    test('une divergence de prix est CONSIGNÉE, sans bloquer', () async {
      // L'argent est dans le tiroir : le prix appliqué fait foi. L'écart se
      // garde pour que l'école sache que la fraîcheur du catalogue a lâché.
      when(() => api.commitSale(any(), any())).thenAnswer(
        (_) async => const BoutiqueSaleResponse(
          saleId: _saleId,
          divergences: [
            PriceDivergenceSignal(
              lineId: _lineId,
              articleId: 'art-polo',
              articleCode: 'POLO',
              appliedPriceInCents: 1500,
              catalogPriceInCents: 1000,
            ),
          ],
        ),
      );

      final result = await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final line = (await db.query(
        'boutique_sale_lines',
        where: 'id = ?',
        whereArgs: [_lineId],
      )).single;
      // Le prix APPLIQUÉ ne bouge pas — c'est l'argent qui a changé de main.
      expect(line['unit_price_in_cents'], 1500);
      // Et ce que le catalogue disait est gardé à côté.
      expect(line['catalog_price_in_cents'], 1000);
    });
  });

  group('classification des échecs', () {
    test('une panne réseau est TRANSITOIRE', () async {
      when(
        () => api.commitSale(any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/')));

      final result = await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      expect(result.outcome, OutboxDispatchOutcome.retry);
      // La vente reste en attente, jamais en échec : le POST est idempotent, et
      // le rejeu rendra 200.
      expect((await saleRow())['sync_status'], 'PENDING_SYNC');
    });

    test('un 500 est TRANSITOIRE', () async {
      when(() => api.commitSale(any(), any())).thenThrow(_http(500));

      final result = await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      expect(result.outcome, OutboxDispatchOutcome.retry);
    });

    test('un 401 est TRANSITOIRE — l\'intercepteur ré-authentifie', () async {
      when(() => api.commitSale(any(), any())).thenThrow(_http(401));

      final result = await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      expect(result.outcome, OutboxDispatchOutcome.retry);
    });

    test('un 422 est TERMINAL, et sa cause est NOMMÉE sur la vente', () async {
      // Le POST est idempotent : un 4xx signifie que le serveur n'a RIEN
      // enregistré. Rejouer jusqu'au poison ne ferait que retarder le même
      // SYNC_ERROR — on surface pour correction.
      when(() => api.commitSale(any(), any())).thenThrow(
        _http(
          422,
          body: {
            'code': 'UNPROCESSABLE',
            'detailCode': BoutiqueErrorCodes.unknownArticle,
            'message': 'Article boutique inconnu : art-polo',
          },
        ),
      );

      final result = await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final row = await saleRow();
      expect(row['sync_status'], 'SYNC_ERROR');
      // La raison est écrite sur la VENTE, pas seulement sur l'entrée d'outbox
      // — celle-ci disparaît, et le guichet doit pouvoir lire des mois plus
      // tard pourquoi cet encaissement n'est jamais arrivé dans les livres.
      expect(row['sync_error'], contains(BoutiqueErrorCodes.unknownArticle));
      // Le montant reste lisible : l'argent reçu n'est jamais « reperdu ».
    });

    test('un 403 sans code retient la vente sans la marquer en échec '
        '(droit retiré, ADR-014 §13.3)', () async {
      when(() => api.commitSale(any(), any())).thenThrow(_http(403));

      final result = await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      expect(result.permissionDenied, isTrue);
      expect((await saleRow())['sync_status'], isNot('SYNC_ERROR'));
    });

    test('un 403 avec code est TERMINAL', () async {
      when(() => api.commitSale(any(), any())).thenThrow(
        _http(403, body: const {'detailCode': 'SOME_BUSINESS_REFUSAL'}),
      );

      final result = await handlerWith(
        OutboxDependencyState.ready,
      ).dispatch(_entry(_request()));

      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect((await saleRow())['sync_status'], 'SYNC_ERROR');
    });

    test('un payload illisible ne se rejoue pas', () async {
      final result = await handlerWith(OutboxDependencyState.ready).dispatch(
        const OutboxEntry(
          id: 'outbox-x',
          aggregateType: BoutiqueSaleWriteDao.aggregateType,
          aggregateId: _saleId,
          operation: OutboxOperation.create,
          payload: 'pas du json',
          schoolId: 'E1',
          createdAt: 0,
        ),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });
  });

  test('le handler s\'abonne bien à BOUTIQUE_SALE', () {
    expect(
      handlerWith(OutboxDependencyState.ready).aggregateType,
      'BOUTIQUE_SALE',
    );
  });
}
