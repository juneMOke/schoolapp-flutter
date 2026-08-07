import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/documents/data/datasources/editique_remote_data_source.dart';

/// Transport factice : mémorise ce qui part réellement sur le fil.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromBytes(
      Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/pdf'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late EditiqueRemoteDataSource dataSource;

  setUp(() {
    adapter = _CapturingAdapter();
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        // Reproduit `createDioClient` : c'est ce `Accept` par défaut que les
        // annotations `@Headers` des routes d'éditique écrasent.
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )..httpClientAdapter = adapter;
    dataSource = EditiqueRemoteDataSource(dio);
  });

  String? acceptHeader() =>
      adapter.captured?.headers[Headers.acceptHeader] as String?;

  // Sans `application/json` dans l'Accept, Spring ne trouve plus de converter
  // capable d'écrire son corps d'erreur `ApiError` : le 404 « Aucune charge
  // pour l'élève » ressort en 500 au corps vide et tout le décodage d'erreur du
  // module devient inopérant. Le PDF, lui, arrive quand même — donc la
  // régression est invisible sur le chemin nominal.
  group('en-tête Accept', () {
    test('accepte le PDF ET le JSON du corps d erreur', () async {
      await dataSource.emitNotePerception(
        const <String, dynamic>{},
        's-1',
        'y-1',
      );

      final accept = acceptHeader();
      expect(accept, isNotNull);
      expect(accept, contains(AppConstants.pdfContentType));
      expect(accept, contains('application/json'));
    });

    test('vaut pour les cinq routes', () async {
      final calls = <String, Future<void> Function()>{
        'attestation': () => dataSource.emitEnrollmentAttestation(
          const <String, dynamic>{},
          'e-1',
        ),
        'note-perception': () => dataSource.emitNotePerception(
          const <String, dynamic>{},
          's-1',
          'y-1',
        ),
        'receipt': () =>
            dataSource.emitPaymentReceipt(const <String, dynamic>{}, 'p-1'),
        'releve': () => dataSource.emitAccountStatement(
          const <String, dynamic>{},
          's-1',
          'y-1',
        ),
        'quitus': () => dataSource.emitFinancialClearance(
          const <String, dynamic>{},
          's-1',
          'y-1',
        ),
      };

      for (final entry in calls.entries) {
        adapter.captured = null;
        await entry.value();
        expect(acceptHeader(), contains('application/json'), reason: entry.key);
        expect(
          acceptHeader(),
          contains(AppConstants.pdfContentType),
          reason: entry.key,
        );
      }
    });
  });

  group('composition de la requête', () {
    test('part en POST, en bytes, sur le chemin contractuel', () async {
      await dataSource.emitPaymentReceipt(const <String, dynamic>{}, 'p-42');

      final captured = adapter.captured!;
      expect(captured.method, 'POST');
      expect(captured.responseType, ResponseType.bytes);
      expect(captured.path, '/api/v1/finance/payments/p-42/receipt');
      expect(captured.data, isNull);
    });

    test('place academicYearId en paramètre de requête', () async {
      await dataSource.emitFinancialClearance(
        const <String, dynamic>{},
        's-7',
        'y-9',
      );

      final captured = adapter.captured!;
      expect(captured.path, '/api/v1/finance/students/s-7/quitus');
      expect(captured.queryParameters['academicYearId'], 'y-9');
    });

    // Les extras voyagent par appel : ils ne doivent jamais muter la map
    // partagée que `RequestOptionsExtra.auth()` fabrique.
    test(
      'transporte les extras d authentification sans les partager',
      () async {
        final extras = <String, dynamic>{'requiresAuth': true};

        await dataSource.emitEnrollmentAttestation(extras, 'e-1');
        final first = adapter.captured!.extra;
        first['pollution'] = true;

        await dataSource.emitEnrollmentAttestation(extras, 'e-2');
        final second = adapter.captured!.extra;

        expect(second['requiresAuth'], isTrue);
        expect(second.containsKey('pollution'), isFalse);
        expect(extras.containsKey('pollution'), isFalse);
      },
    );
  });
}
