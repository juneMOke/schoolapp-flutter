import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/documents/data/datasources/editique_remote_data_source.dart';
import 'package:school_app_flutter/features/documents/data/repositories/editique_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

class MockEditiqueRemoteDataSource extends Mock
    implements EditiqueRemoteDataSource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

Uint8List _pdfBytes() =>
    Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]);

HttpResponse<Uint8List> _pdfResponse({String? contentDisposition}) {
  final headerMap = <String, List<String>>{
    Headers.contentTypeHeader: <String>['application/pdf'],
    if (contentDisposition != null)
      'content-disposition': <String>[contentDisposition],
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

void main() {
  late MockEditiqueRemoteDataSource dataSource;
  late MockConnectivityService connectivity;
  late EditiqueRepositoryImpl repository;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() {
    dataSource = MockEditiqueRemoteDataSource();
    connectivity = MockConnectivityService();
    repository = EditiqueRepositoryImpl(
      remoteDataSource: dataSource,
      connectivityService: connectivity,
      requiredAuth: auth,
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
}
