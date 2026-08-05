import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_server_detail.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/documents/data/datasources/editique_remote_data_source.dart';
import 'package:school_app_flutter/features/documents/data/repositories/editique_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

class MockEditiqueRemoteDataSource extends Mock
    implements EditiqueRemoteDataSource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

Uint8List _pdfBytes() =>
    Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]);

HttpResponse<Uint8List> _pdfResponse({
  String? contentDisposition,
  String? documentId,
}) {
  final headerMap = <String, List<String>>{
    Headers.contentTypeHeader: <String>['application/pdf'],
    if (contentDisposition != null)
      'content-disposition': <String>[contentDisposition],
    if (documentId != null) 'x-document-id': <String>[documentId],
  };

  return HttpResponse<Uint8List>(
    _pdfBytes(),
    Response<Uint8List>(
      requestOptions: RequestOptions(path: '/api/v1/whatever'),
      statusCode: 200,
      headers: Headers.fromMap(headerMap),
      data: _pdfBytes(),
    ),
  );
}

class MockEditiqueDocumentCache extends Mock implements EditiqueDocumentCache {}

void main() {
  late MockEditiqueRemoteDataSource dataSource;
  late MockConnectivityService connectivity;
  late MockEditiqueDocumentCache cache;
  late CurrentUserContext currentUser;
  late EditiqueRepositoryImpl repository;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() {
    // `any(named: 'bytes')` sur la mise en cache : mocktail exige une valeur
    // de repli pour tout type non primitif.
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    dataSource = MockEditiqueRemoteDataSource();
    connectivity = MockConnectivityService();
    cache = MockEditiqueDocumentCache();
    // Cache muet par défaut : le chemin d'émission ne doit pas dépendre de ce
    // qu'il rend, et une mise en cache est toujours best-effort.
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
        bytes: any(named: 'bytes'),
      ),
    ).thenAnswer((_) async => null);
    when(() => cache.readByDocumentId(any())).thenAnswer((_) async => null);
    when(
      () => cache.readByDocumentNumber(
        schoolId: any(named: 'schoolId'),
        documentNumber: any(named: 'documentNumber'),
      ),
    ).thenAnswer((_) async => null);
    currentUser = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    repository = EditiqueRepositoryImpl(
      remoteDataSource: dataSource,
      connectivityService: connectivity,
      requiredAuth: auth,
      cache: cache,
      currentUser: currentUser,
    );
  });

  void goOnline() =>
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
  void goOffline() =>
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);

  group('pré-garde de connectivité', () {
    test(
      'échoue en réseau sans appeler le serveur quand la radio est coupée',
      () async {
        goOffline();

        final result = await repository.emitPaymentReceipt(paymentId: 'p-1');

        expect(result.isLeft(), isTrue);
        result.fold((f) => expect(f, isA<NetworkFailure>()), (_) {});
        verifyNever(() => dataSource.emitPaymentReceipt(any(), any()));
      },
    );

    test('la pré-garde protège chacune des cinq routes', () async {
      goOffline();

      final results = await Future.wait(<Future<Either<Failure, Object>>>[
        repository.emitEnrollmentAttestation(enrollmentId: 'e-1'),
        repository.emitNotePerception(studentId: 's-1', academicYearId: 'y-1'),
        repository.emitPaymentReceipt(paymentId: 'p-1'),
        repository.emitAccountStatement(
          studentId: 's-1',
          academicYearId: 'y-1',
        ),
        repository.emitFinancialClearance(
          studentId: 's-1',
          academicYearId: 'y-1',
        ),
      ]);

      expect(results, hasLength(5));
      for (final result in results) {
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('attendu Left hors ligne'),
        );
      }
      verifyZeroInteractions(dataSource);
    });
  });

  group('émission réussie', () {
    test('attestation : transmet l identifiant et les extras d auth', () async {
      goOnline();
      when(() => dataSource.emitEnrollmentAttestation(any(), any())).thenAnswer(
        (_) async => _pdfResponse(
          contentDisposition: 'attachment; filename="ETL-AI-2526-000087.pdf"',
        ),
      );

      final result = await repository.emitEnrollmentAttestation(
        enrollmentId: 'e-42',
      );

      final document = result.getOrElse(
        () => throw StateError('attendu Right'),
      );
      expect(document.type, EditiqueDocumentType.enrollmentAttestation);
      expect(document.documentNumber, 'ETL-AI-2526-000087');
      verify(
        () => dataSource.emitEnrollmentAttestation(auth, 'e-42'),
      ).called(1);
    });

    test('note de perception : transmet élève et année', () async {
      goOnline();
      when(
        () => dataSource.emitNotePerception(any(), any(), any()),
      ).thenAnswer((_) async => _pdfResponse());

      final result = await repository.emitNotePerception(
        studentId: 's-7',
        academicYearId: 'y-9',
      );

      expect(result.isRight(), isTrue);
      verify(() => dataSource.emitNotePerception(auth, 's-7', 'y-9')).called(1);
    });

    test('relevé : produit un document explicitement non rejouable', () async {
      goOnline();
      when(
        () => dataSource.emitAccountStatement(any(), any(), any()),
      ).thenAnswer((_) async => _pdfResponse());

      final result = await repository.emitAccountStatement(
        studentId: 's-7',
        academicYearId: 'y-9',
      );

      final document = result.getOrElse(
        () => throw StateError('attendu Right'),
      );
      expect(document.isReplayable, isFalse);
    });

    test('quitus : transmet élève et année', () async {
      goOnline();
      when(
        () => dataSource.emitFinancialClearance(any(), any(), any()),
      ).thenAnswer((_) async => _pdfResponse());

      final result = await repository.emitFinancialClearance(
        studentId: 's-7',
        academicYearId: 'y-9',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => dataSource.emitFinancialClearance(auth, 's-7', 'y-9'),
      ).called(1);
    });
  });

  group('échecs', () {
    test('propage la Failure classée avec le message du serveur', () async {
      goOnline();
      final options = RequestOptions(path: '/api/v1/whatever');
      when(() => dataSource.emitPaymentReceipt(any(), any())).thenThrow(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          error: const NotFoundFailure(),
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 404,
            data: '{"message":"Paiement introuvable"}',
          ),
        ),
      );

      final result = await repository.emitPaymentReceipt(paymentId: 'p-404');

      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Paiement introuvable');
      }, (_) => fail('attendu Left'));
    });

    test(
      'un dépassement de délai de réception donne une issue inconnue',
      () async {
        goOnline();
        when(
          () => dataSource.emitAccountStatement(any(), any(), any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/whatever'),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        final result = await repository.emitAccountStatement(
          studentId: 's-1',
          academicYearId: 'y-1',
        );

        result.fold(
          (failure) => expect(failure, isA<UncertainOutcomeFailure>()),
          (_) => fail('attendu Left'),
        );
      },
    );

    test('refuse un corps qui n est pas un PDF', () async {
      goOnline();
      when(() => dataSource.emitPaymentReceipt(any(), any())).thenAnswer((_) {
        final options = RequestOptions(path: '/api/v1/whatever');
        return Future<HttpResponse<Uint8List>>.value(
          HttpResponse<Uint8List>(
            Uint8List.fromList(<int>[0x3C, 0x68, 0x74, 0x6D, 0x6C]),
            Response<Uint8List>(
              requestOptions: options,
              statusCode: 200,
              headers: Headers.fromMap(<String, List<String>>{
                Headers.contentTypeHeader: <String>['text/html'],
              }),
            ),
          ),
        );
      });

      final result = await repository.emitPaymentReceipt(paymentId: 'p-1');

      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('attendu Left'),
      );
    });

    // Une exception non-Dio survient à un moment indéterminé du cycle : le
    // serveur a pu traiter la requête. Sur RL/QT, un numéro peut déjà être
    // consommé — ce cas ne doit jamais être présenté comme « rien n'est parti ».
    test('une exception inattendue donne une issue inconnue', () async {
      goOnline();
      when(
        () => dataSource.emitFinancialClearance(any(), any(), any()),
      ).thenThrow(StateError('boum'));

      final result = await repository.emitFinancialClearance(
        studentId: 's-1',
        academicYearId: 'y-1',
      );

      result.fold(
        (failure) => expect(failure, isA<UncertainOutcomeFailure>()),
        (_) => fail('attendu Left'),
      );
    });
  });

  // ── L3.5 : les deux verbes de D-1 ─────────────────────────────────────────
  // Ce repository est, en V1, le SEUL à remplir le cache : il n'existe aucun
  // pull de métadonnées. Câbler la lecture sans l'écriture donnerait un cache
  // qui reste vide à jamais, sans qu'un seul test devienne rouge — d'où ce
  // groupe.
  group('remplissage du cache', () {
    test('une émission archivée dépose sa copie', () async {
      goOnline();
      when(() => dataSource.emitNotePerception(any(), any(), any())).thenAnswer(
        (_) async => _pdfResponse(
          contentDisposition: 'attachment; filename="ETL-NP-2526-000009.pdf"',
          documentId: 'doc-np-1',
        ),
      );

      await repository.emitNotePerception(
        studentId: 's-1',
        academicYearId: 'y-1',
      );

      final call = verify(
        () => cache.put(
          docType: 'NP',
          documentId: 'doc-np-1',
          documentNumber: 'ETL-NP-2526-000009',
          // La note de perception est la seule émission qui nomme son élève et
          // son année : elles doivent atterrir dans l'index.
          studentId: 's-1',
          academicYearId: 'y-1',
          schoolId: 'school-1',
          ownerUid: 'u-1',
          emittedAt: null,
          bytes: captureAny(named: 'bytes'),
        ),
      )..called(1);
      // Les octets déposés sont ceux reçus, sans recomposition (RG-012-3).
      expect(call.captured.single, _pdfBytes());
    });

    // Le défaut que la revue a trouvé : sans élève, la copie est bien écrite
    // mais AUCUN écran ne peut la ressortir — la seule lecture branchée au
    // catalogue filtre sur `student_id`, et une colonne NULL ne satisfait
    // jamais une égalité. Les octets occupaient le budget sans servir.
    test('une attestation dépose sa copie AVEC son élève', () async {
      goOnline();
      when(
        () => dataSource.emitEnrollmentAttestation(any(), any()),
      ).thenAnswer((_) async => _pdfResponse(documentId: 'doc-ai-1'));

      await repository.emitEnrollmentAttestation(
        enrollmentId: 'e-1',
        studentId: 's-1',
        academicYearId: 'y-1',
      );

      verify(
        () => cache.put(
          docType: 'AI',
          documentId: 'doc-ai-1',
          documentNumber: any(named: 'documentNumber'),
          studentId: 's-1',
          academicYearId: 'y-1',
          schoolId: 'school-1',
          ownerUid: 'u-1',
          emittedAt: null,
          bytes: any(named: 'bytes'),
        ),
      ).called(1);
    });

    // Même piège sur le re-téléchargement : recréer la ligne sans attribution
    // ferait disparaître du catalogue une pièce qui y figurait.
    test('un re-téléchargement dépose sa copie AVEC son élève', () async {
      goOnline();
      when(
        () => dataSource.downloadDocument(any(), any()),
      ).thenAnswer((_) async => _pdfResponse());

      await repository.restitute(
        type: EditiqueDocumentType.notePerception,
        documentId: 'doc-np-2',
        studentId: 's-1',
        academicYearId: 'y-1',
      );

      verify(
        () => cache.put(
          docType: 'NP',
          documentId: 'doc-np-2',
          documentNumber: any(named: 'documentNumber'),
          studentId: 's-1',
          academicYearId: 'y-1',
          schoolId: 'school-1',
          ownerUid: 'u-1',
          emittedAt: null,
          bytes: any(named: 'bytes'),
        ),
      ).called(1);
    });

    // Le serveur ne les conserve pas : une copie locale en serait l'unique
    // exemplaire au monde, et l'éviction la détruirait.
    test('une pièce horodatée n est jamais mise en cache', () async {
      goOnline();
      when(
        () => dataSource.emitAccountStatement(any(), any(), any()),
      ).thenAnswer((_) async => _pdfResponse());
      when(
        () => dataSource.emitFinancialClearance(any(), any(), any()),
      ).thenAnswer((_) async => _pdfResponse());

      await repository.emitAccountStatement(
        studentId: 's-1',
        academicYearId: 'y-1',
      );
      await repository.emitFinancialClearance(
        studentId: 's-1',
        academicYearId: 'y-1',
      );

      _verifyNothingCached(cache);
    });

    test('une émission en échec ne dépose rien', () async {
      goOnline();
      when(() => dataSource.emitPaymentReceipt(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 404,
          ),
        ),
      );

      await repository.emitPaymentReceipt(paymentId: 'p-1');

      _verifyNothingCached(cache);
    });

    // La portée de lecture d'une entrée est l'école : sans elle, la copie
    // serait introuvable.
    test('sans école courante, rien n est déposé', () async {
      goOnline();
      currentUser.clear();
      when(
        () => dataSource.emitPaymentReceipt(any(), any()),
      ).thenAnswer((_) async => _pdfResponse(documentId: 'doc-rc-1'));

      final result = await repository.emitPaymentReceipt(paymentId: 'p-1');

      expect(result.isRight(), isTrue);
      _verifyNothingCached(cache);
    });

    // Une pièce qu'on n'a pas su cacher a quand même été produite : c'est elle
    // que l'appelant attend.
    test('un cache en panne ne fait pas échouer l émission', () async {
      goOnline();
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
          bytes: any(named: 'bytes'),
        ),
      ).thenThrow(StateError('disque plein'));
      when(
        () => dataSource.emitPaymentReceipt(any(), any()),
      ).thenAnswer((_) async => _pdfResponse(documentId: 'doc-rc-1'));

      final result = await repository.emitPaymentReceipt(paymentId: 'p-1');

      expect(result.isRight(), isTrue);
    });
  });

  group('restitution', () {
    test('sert la copie locale sans toucher au réseau', () async {
      when(
        () => cache.readByDocumentId('doc-1'),
      ).thenAnswer((_) async => _pdfBytes());

      final result = await repository.restitute(
        type: EditiqueDocumentType.paymentReceipt,
        documentId: 'doc-1',
      );

      result.fold((f) => fail('attendu Right, reçu $f'), (document) {
        expect(document.bytes, _pdfBytes());
        expect(document.documentId, 'doc-1');
      });
      verifyNever(() => dataSource.downloadDocument(any(), any()));
      // Aucune pré-garde de connectivité : ressortir ce qu'on détient n'exige
      // pas de réseau.
      verifyNever(() => connectivity.isOnline());
    });

    test(
      'cherche par numéro, dans l école courante, faute d identifiant',
      () async {
        when(
          () => cache.readByDocumentNumber(
            schoolId: 'school-1',
            documentNumber: 'ETL-RC-2526-000001',
          ),
        ).thenAnswer((_) async => _pdfBytes());

        final result = await repository.restitute(
          type: EditiqueDocumentType.paymentReceipt,
          documentNumber: 'ETL-RC-2526-000001',
        );

        expect(result.isRight(), isTrue);
      },
    );

    test('re-télécharge quand la copie manque, et la garde', () async {
      goOnline();
      when(() => dataSource.downloadDocument(any(), any())).thenAnswer(
        (_) async => _pdfResponse(
          contentDisposition: 'attachment; filename="ETL-AI-2526-000087.pdf"',
        ),
      );

      final result = await repository.restitute(
        type: EditiqueDocumentType.enrollmentAttestation,
        documentId: 'doc-ai-1',
      );

      expect(result.isRight(), isTrue);
      verify(() => dataSource.downloadDocument(auth, 'doc-ai-1')).called(1);
      // Sans ce dépôt, une pièce scellée par une AUTRE tablette resterait hors
      // de portée hors ligne pour toujours.
      verify(
        () => cache.put(
          docType: 'AI',
          documentId: 'doc-ai-1',
          documentNumber: 'ETL-AI-2526-000087',
          studentId: null,
          academicYearId: null,
          schoolId: 'school-1',
          ownerUid: 'u-1',
          emittedAt: null,
          bytes: any(named: 'bytes'),
        ),
      ).called(1);
    });

    test('hors ligne et sans copie, le dit sans appeler', () async {
      goOffline();

      final result = await repository.restitute(
        type: EditiqueDocumentType.notePerception,
        documentId: 'doc-np-1',
      );

      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
      verifyNever(() => dataSource.downloadDocument(any(), any()));
    });

    // Ces deux échecs sont fabriqués par le client. La présentation affiche le
    // message d'une `Failure` sous le libellé « Motif renvoyé par le serveur » :
    // y glisser une phrase écrite ici mentirait sur son origine et
    // court-circuiterait `AppLocalizations`.
    test('les échecs locaux ne portent aucun message de serveur', () async {
      goOffline();
      final horsLigne = await repository.restitute(
        type: EditiqueDocumentType.notePerception,
        documentId: 'doc-np-1',
      );
      final sansIdentifiant = await repository.restitute(
        type: EditiqueDocumentType.paymentReceipt,
        documentNumber: 'ETL-RC-2526-000001',
      );

      expect(
        EditiqueServerDetail.of(horsLigne.fold((f) => f, (_) => throw 'x')),
        isNull,
      );
      expect(
        EditiqueServerDetail.of(
          sansIdentifiant.fold((f) => f, (_) => throw 'x'),
        ),
        isNull,
      );
    });

    // Le serveur n'expose aucune recherche par numéro : sans identifiant, il
    // n'y a rien à télécharger, en ligne comme hors ligne.
    test('un numéro seul sans copie ne déclenche aucun appel', () async {
      final result = await repository.restitute(
        type: EditiqueDocumentType.paymentReceipt,
        documentNumber: 'ETL-RC-2526-000001',
      );

      expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
      verifyNever(() => dataSource.downloadDocument(any(), any()));
      verifyNever(() => connectivity.isOnline());
    });

    // Une pièce recalculée à chaque demande n'a rien à restituer : c'est une
    // faute d'appelant, pas un cas d'échec.
    test('refuse une pièce que le serveur n archive pas', () async {
      expect(
        () => repository.restitute(
          type: EditiqueDocumentType.accountStatement,
          documentId: 'doc-rl-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.restitute(
          type: EditiqueDocumentType.financialClearance,
          documentId: 'doc-qt-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuse une demande que rien ne désigne', () async {
      expect(
        () => repository.restitute(
          type: EditiqueDocumentType.paymentReceipt,
          documentNumber: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // Un GET ne produit rien et ne consomme aucun numéro : l'échec se réessaie
    // librement, ce qu'un verdict incertain interdirait.
    test('un échec de re-téléchargement n est jamais incertain', () async {
      goOnline();
      when(
        () => dataSource.downloadDocument(any(), any()),
      ).thenThrow(StateError('panne locale'));

      final result = await repository.restitute(
        type: EditiqueDocumentType.paymentReceipt,
        documentId: 'doc-1',
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
      expect(failure, isNot(isA<UncertainOutcomeFailure>()));
    });
  });
}

/// Aucune copie n'a été déposée, quels qu'en soient les champs.
void _verifyNothingCached(MockEditiqueDocumentCache cache) {
  verifyNever(
    () => cache.put(
      docType: any(named: 'docType'),
      documentId: any(named: 'documentId'),
      documentNumber: any(named: 'documentNumber'),
      studentId: any(named: 'studentId'),
      academicYearId: any(named: 'academicYearId'),
      schoolId: any(named: 'schoolId'),
      ownerUid: any(named: 'ownerUid'),
      emittedAt: any(named: 'emittedAt'),
      bytes: any(named: 'bytes'),
    ),
  );
}
