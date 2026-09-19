import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_write_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_receipt_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sync_api.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

class _MockApi extends Mock implements BoutiqueSyncApi {}

class _MockDao extends Mock implements BoutiqueSaleWriteDao {}

class _MockConnectivity extends Mock implements ConnectivityService {}

/// Octets minimaux acceptés comme PDF : signature `%PDF` puis un peu de contenu.
Uint8List _pdfBytes() =>
    Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]);

HttpResponse<Uint8List> _response({
  Uint8List? bytes,
  String? contentType = 'application/pdf',
  String? contentDisposition = 'attachment; filename="ETL-RV-2526-000413.pdf"',
  String? documentId = 'doc-7',
}) {
  final headerMap = <String, List<String>>{};
  if (contentType != null) {
    headerMap[Headers.contentTypeHeader] = <String>[contentType];
  }
  if (contentDisposition != null) {
    headerMap['content-disposition'] = <String>[contentDisposition];
  }
  if (documentId != null) {
    headerMap['x-document-id'] = <String>[documentId];
  }

  return HttpResponse<Uint8List>(
    bytes ?? _pdfBytes(),
    Response<Uint8List>(
      requestOptions: RequestOptions(
        path: '/api/v1/boutique/sales/s-1/receipt',
      ),
      statusCode: 200,
      headers: Headers.fromMap(headerMap),
      data: bytes ?? _pdfBytes(),
    ),
  );
}

/// La **réclamation** du reçu de vente scellé.
///
/// Ce que ces cas défendent : le guichet obtient sa pièce, la base apprend ce
/// que le serveur a annoncé — et ni l'un ni l'autre ne dépend de l'autre pour
/// réussir.
void main() {
  late _MockApi api;
  late _MockDao dao;
  late _MockConnectivity connectivity;

  BoutiqueReceiptRepositoryImpl repo() => BoutiqueReceiptRepositoryImpl(
    api: api,
    dao: dao,
    connectivity: connectivity,
    requiredAuth: const <String, dynamic>{'requiresAuth': true},
    now: () => 900,
  );

  setUp(() {
    api = _MockApi();
    dao = _MockDao();
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    when(
      () => dao.applyClaimedReceipt(
        any(),
        nowMs: any(named: 'nowMs'),
        documentId: any(named: 'documentId'),
        documentNumber: any(named: 'documentNumber'),
      ),
    ).thenAnswer((_) async {});
  });

  EditiqueDocument rightOf(dynamic result) => result.fold(
    (failure) => fail('Attendu Right, reçu Left($failure)'),
    (document) => document as EditiqueDocument,
  );

  group('cas nominal', () {
    test('la piece revient, et la base apprend ses deux references', () async {
      when(
        () => api.emitSaleReceipt(any(), any()),
      ).thenAnswer((_) async => _response());

      final document = rightOf(await repo().claimSaleReceipt('s-1'));

      expect(document.type, EditiqueDocumentType.saleReceipt);
      expect(document.bytes, _pdfBytes());
      expect(document.documentId, 'doc-7');
      expect(document.documentNumber, 'ETL-RV-2526-000413');
      // C'est ce numéro-là qui fait disparaître le `PROV-` de l'écran et des
      // tickets réimprimés ensuite.
      verify(
        () => dao.applyClaimedReceipt(
          's-1',
          nowMs: 900,
          documentId: 'doc-7',
          documentNumber: 'ETL-RV-2526-000413',
        ),
      ).called(1);
    });

    test('le jeton d authentification part avec la demande', () async {
      // La route exige `boutique.sale.write` ET `editique.write` : sans le
      // marqueur, l'intercepteur n'attache pas le porteur et le serveur rend 401.
      when(
        () => api.emitSaleReceipt(any(), any()),
      ).thenAnswer((_) async => _response());

      await repo().claimSaleReceipt('s-1');

      verify(
        () => api.emitSaleReceipt(const <String, dynamic>{
          'requiresAuth': true,
        }, 's-1'),
      ).called(1);
    });

    test('la piece est rendue MEME si le serveur taît son numero', () async {
      // Cas normal et non dégradé : le numéro ne voyage que dans un
      // `Content-Disposition` que le contrat ne documente sur aucune route.
      when(
        () => api.emitSaleReceipt(any(), any()),
      ).thenAnswer((_) async => _response(contentDisposition: null));

      final document = rightOf(await repo().claimSaleReceipt('s-1'));

      expect(document.documentNumber, isNull);
      expect(document.fileName, 'document-rv.pdf');
      verify(
        () => dao.applyClaimedReceipt(
          's-1',
          nowMs: 900,
          documentId: 'doc-7',
          documentNumber: null,
        ),
      ).called(1);
    });

    test('un echec d ecriture locale ne fait PAS perdre la piece', () async {
      // Les octets sont en main et le payeur attend son papier. La route étant
      // idempotente, la réclamation se refait — refuser la pièce ici serait
      // absurde.
      when(
        () => api.emitSaleReceipt(any(), any()),
      ).thenAnswer((_) async => _response());
      when(
        () => dao.applyClaimedReceipt(
          any(),
          nowMs: any(named: 'nowMs'),
          documentId: any(named: 'documentId'),
          documentNumber: any(named: 'documentNumber'),
        ),
      ).thenThrow(Exception('base verrouillée'));

      final result = await repo().claimSaleReceipt('s-1');

      expect(result.isRight(), isTrue);
    });
  });

  group('rien ne part, ou rien d exploitable ne revient', () {
    test('hors ligne : refus IMMEDIAT, aucun appel', () async {
      // Sans cette pré-garde, l'appel coûte le `connectTimeout` de la requête
      // PDF plus celui du mint de jeton — de l'ordre de 12 s pour une issue
      // connue d'avance.
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);

      final result = await repo().claimSaleReceipt('s-1');

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('Left'));
      verifyNever(() => api.emitSaleReceipt(any(), any()));
      verifyNever(
        () => dao.applyClaimedReceipt(
          any(),
          nowMs: any(named: 'nowMs'),
          documentId: any(named: 'documentId'),
          documentNumber: any(named: 'documentNumber'),
        ),
      );
    });

    test(
      'un 200 qui n est pas un PDF est REFUSE, et rien n est ecrit',
      () async {
        // Un portail captif répond 200 avec du HTML. Consigner ses références
        // ferait croire à une pièce scellée qui n'existe pas.
        when(
          () => api.emitSaleReceipt(any(), any()),
        ).thenAnswer((_) async => _response(contentType: 'text/html'));

        final result = await repo().claimSaleReceipt('s-1');

        result.fold(
          (f) => expect(f, isA<ServerFailure>()),
          (_) => fail('Left'),
        );
        verifyNever(
          () => dao.applyClaimedReceipt(
            any(),
            nowMs: any(named: 'nowMs'),
            documentId: any(named: 'documentId'),
            documentNumber: any(named: 'documentNumber'),
          ),
        );
      },
    );

    test('le type de Failure classe par l intercepteur est PRESERVE', () async {
      // Une vente introuvable côté serveur n'est pas une panne : l'écran en dit
      // autre chose.
      when(() => api.emitSaleReceipt(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          response: Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 404,
          ),
          error: const NotFoundFailure('Vente introuvable'),
        ),
      );

      final result = await repo().claimSaleReceipt('s-1');

      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Left attendu'),
      );
    });

    test('une coupure de transport reste un echec RESEAU', () async {
      when(() => api.emitSaleReceipt(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repo().claimSaleReceipt('s-1');

      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('Left'));
    });
  });
}
