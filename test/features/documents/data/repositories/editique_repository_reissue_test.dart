import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/datasources/editique_remote_data_source.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/features/documents/data/repositories/editique_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

class _MockRemote extends Mock implements EditiqueRemoteDataSource {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockCache extends Mock implements EditiqueDocumentCache {}

Uint8List _pdf() =>
    Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]);

HttpResponse<Uint8List> _replacement({String? documentId, String? edition}) =>
    HttpResponse<Uint8List>(
      _pdf(),
      Response<Uint8List>(
        requestOptions: RequestOptions(path: '/reissue'),
        statusCode: 200,
        headers: Headers.fromMap(<String, List<String>>{
          Headers.contentTypeHeader: <String>['application/pdf'],
          'content-disposition': <String>[
            'attachment; filename="ETL-AI-2526-000087.pdf"',
          ],
          if (documentId != null) 'x-document-id': <String>[documentId],
          if (edition != null) 'x-document-edition': <String>[edition],
        }),
        data: _pdf(),
      ),
    );

void main() {
  late _MockRemote remote;
  late _MockConnectivity connectivity;
  late _MockCache cache;
  late EditiqueRepositoryImpl repository;

  const auth = <String, dynamic>{'requiresAuth': true};
  const reason = 'Niveau corrigé (M2 → P2)';

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() {
    remote = _MockRemote();
    connectivity = _MockConnectivity();
    cache = _MockCache();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    when(
      () => cache.markCancelled(
        documentId: any(named: 'documentId'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => cache.put(
        docType: any(named: 'docType'),
        documentId: any(named: 'documentId'),
        documentNumber: any(named: 'documentNumber'),
        studentId: any(named: 'studentId'),
        academicYearId: any(named: 'academicYearId'),
        schoolId: any(named: 'schoolId'),
        ownerUid: any(named: 'ownerUid'),
        emittedAt: any(named: 'emittedAt'),
        verificationUrl: any(named: 'verificationUrl'),
        edition: any(named: 'edition'),
        bytes: any(named: 'bytes'),
      ),
    ).thenAnswer((_) async => null);
    repository = EditiqueRepositoryImpl(
      remoteDataSource: remote,
      connectivityService: connectivity,
      requiredAuth: auth,
      cache: cache,
      currentUser: CurrentUserContext()..set('u-1', schoolId: 'school-1'),
    );
  });

  Future<dynamic> reissue() => repository.reissue(
    type: EditiqueDocumentType.enrollmentAttestation,
    documentId: 'doc-1',
    reason: reason,
    studentId: 's-1',
    academicYearId: 'y-1',
  );

  test('envoie le motif, annule la pièce remplacée et range la remplaçante '
      'avec son édition', () async {
    when(
      () => remote.reissueDocument(auth, 'doc-1', {'reason': reason}),
    ).thenAnswer((_) async => _replacement(documentId: 'doc-2', edition: '2'));

    final result = await reissue();

    result.fold((_) => fail('attendu Right'), (document) {
      expect(document.documentId, 'doc-2');
      expect(document.edition, 2);
    });
    verify(
      () => cache.markCancelled(documentId: 'doc-1', reason: reason),
    ).called(1);
    verify(
      () => cache.put(
        docType: 'AI',
        documentId: 'doc-2',
        documentNumber: 'ETL-AI-2526-000087',
        studentId: 's-1',
        academicYearId: 'y-1',
        schoolId: 'school-1',
        ownerUid: any(named: 'ownerUid'),
        emittedAt: any(named: 'emittedAt'),
        verificationUrl: any(named: 'verificationUrl'),
        edition: 2,
        bytes: any(named: 'bytes'),
      ),
    ).called(1);
  });

  test('une remplaçante sans identifiant ne touche pas au cache : par son '
      'seul numéro, elle écraserait la pièce remplacée', () async {
    when(
      () => remote.reissueDocument(any(), any(), any()),
    ).thenAnswer((_) async => _replacement());

    final result = await reissue();

    expect(result.isRight(), isTrue);
    verifyNever(
      () => cache.markCancelled(
        documentId: any(named: 'documentId'),
        reason: any(named: 'reason'),
      ),
    );
  });

  test('hors ligne : échec réseau, rien n\'est envoyé', () async {
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);

    final result = await reissue();

    result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('Left'));
    verifyNever(() => remote.reissueDocument(any(), any(), any()));
  });

  test('un refus du serveur remonte sans rien annuler localement', () async {
    when(() => remote.reissueDocument(any(), any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reissue'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/reissue'),
          statusCode: 403,
        ),
      ),
    );

    final result = await reissue();

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => cache.markCancelled(
        documentId: any(named: 'documentId'),
        reason: any(named: 'reason'),
      ),
    );
  });

  test(
    'une issue inconnue reste réessayable : la route est rejouable',
    () async {
      when(
        () => remote.reissueDocument(any(), any(), any()),
      ).thenThrow(StateError('boom'));

      final result = await reissue();

      result.fold(
        (f) => expect(f, isNot(isA<UncertainOutcomeFailure>())),
        (_) => fail('attendu Left'),
      );
    },
  );

  test('un reçu ne se réémet pas : faute d\'appelant', () {
    expect(
      () => repository.reissue(
        type: EditiqueDocumentType.paymentReceipt,
        documentId: 'doc-1',
        reason: reason,
      ),
      throwsArgumentError,
    );
  });
}
