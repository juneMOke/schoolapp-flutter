import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';

RequestOptions _options() => RequestOptions(path: '/api/v1/whatever');

Uint8List _apiError(String message) => Uint8List.fromList(
  utf8.encode(
    jsonEncode(<String, dynamic>{
      'status': 404,
      'error': 'Not Found',
      'message': message,
    }),
  ),
);

DioException _badResponse({
  required Failure classified,
  Object? body,
  int statusCode = 404,
}) {
  final options = _options();
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    error: classified,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: body,
    ),
  );
}

void main() {
  group('EditiqueFailureMapper — réponses HTTP classées', () {
    test('rend au 404 le message du serveur sans changer son type', () {
      final failure = EditiqueFailureMapper.fromDioException(
        _badResponse(
          classified: const NotFoundFailure(),
          body: _apiError("Aucune charge pour l'élève"),
        ),
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, "Aucune charge pour l'élève");
    });

    test('rend au 422 le message du serveur sans changer son type', () {
      final failure = EditiqueFailureMapper.fromDioException(
        _badResponse(
          classified: const ValidationFailure(),
          statusCode: 422,
          body: _apiError('Charges en devises multiples'),
        ),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Charges en devises multiples');
    });

    test('conserve la Failure telle quelle si le corps est illisible', () {
      const classified = NotFoundFailure('Resource not found');
      final failure = EditiqueFailureMapper.fromDioException(
        _badResponse(
          classified: classified,
          body: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]),
        ),
      );

      expect(failure, same(classified));
      expect(failure.message, 'Resource not found');
    });

    test('préserve chaque type classé par l intercepteur global', () {
      final cases = <Failure>[
        const InvalidCredentialsFailure(),
        const UnauthorizedFailure(),
        const NotFoundFailure(),
        const ValidationFailure(),
        const ConflictFailure(),
        const ServerFailure(),
      ];

      for (final classified in cases) {
        final failure = EditiqueFailureMapper.fromDioException(
          _badResponse(classified: classified, body: _apiError('détail')),
        );
        expect(
          failure.runtimeType,
          classified.runtimeType,
          reason: '${classified.runtimeType}',
        );
        expect(failure.message, 'détail');
      }
    });
  });

  group('EditiqueFailureMapper — échecs de transport', () {
    Failure mapType(DioExceptionType type) =>
        EditiqueFailureMapper.fromDioException(
          DioException(requestOptions: _options(), type: type),
        );

    // La requête n'a jamais atteint le serveur : rien n'a pu être produit.
    test('connectionTimeout et connectionError sont des échecs réseau', () {
      expect(
        mapType(DioExceptionType.connectionTimeout),
        isA<NetworkFailure>(),
      );
      expect(mapType(DioExceptionType.connectionError), isA<NetworkFailure>());
      expect(mapType(DioExceptionType.badCertificate), isA<NetworkFailure>());
    });

    // Cœur de la règle money-grade : le serveur rend le PDF avant d'écrire le
    // premier octet, donc un receiveTimeout signifie « peut-être émis, numéro
    // peut-être brûlé » — jamais « rien ne s'est passé ».
    test('receiveTimeout signale une issue inconnue, pas un échec réseau', () {
      final failure = mapType(DioExceptionType.receiveTimeout);
      expect(failure, isA<UncertainOutcomeFailure>());
      expect(failure, isNot(isA<NetworkFailure>()));
    });

    test('sendTimeout, cancel et unknown signalent une issue inconnue', () {
      expect(
        mapType(DioExceptionType.sendTimeout),
        isA<UncertainOutcomeFailure>(),
      );
      expect(mapType(DioExceptionType.cancel), isA<UncertainOutcomeFailure>());
      expect(mapType(DioExceptionType.unknown), isA<UncertainOutcomeFailure>());
    });

    test('un badResponse non classé retombe en erreur serveur', () {
      final failure = EditiqueFailureMapper.fromDioException(
        DioException(
          requestOptions: _options(),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: _options(),
            statusCode: 302,
          ),
        ),
      );
      expect(failure, isA<ServerFailure>());
    });

    test('un message serveur présent prime sur le message par défaut', () {
      final options = _options();
      final failure = EditiqueFailureMapper.fromDioException(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 302,
            data: _apiError('Redirection inattendue'),
          ),
        ),
      );
      expect(failure.message, 'Redirection inattendue');
    });
  });
}
