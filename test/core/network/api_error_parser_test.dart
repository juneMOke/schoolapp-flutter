import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';

Response<dynamic> _response({
  dynamic data,
  int statusCode = 400,
  Map<String, List<String>> headers = const {},
}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/v1/provisioning/apply'),
    statusCode: statusCode,
    data: data,
    headers: Headers.fromMap(headers),
  );
}

void main() {
  group('ApiErrorParser — lecture de l\'enveloppe', () {
    test('lit le code typé servi', () {
      final response = _response(
        data: {'status': 400, 'code': 'BUSINESS_RULE', 'message': 'Déjà là'},
      );

      expect(ApiErrorParser.codeOf(response), ApiErrorCode.businessRule);
      expect(ApiErrorParser.serverMessageOf(response), 'Déjà là');
    });

    test('un code inédit dégrade en unknown, sans lever', () {
      final response = _response(data: {'code': 'QUOTA_EXCEEDED'});

      expect(ApiErrorParser.codeOf(response), ApiErrorCode.unknown);
    });

    test('lit le corps rendu en chaîne JSON', () {
      final response = _response(data: jsonEncode({'code': 'UNPROCESSABLE'}));

      expect(ApiErrorParser.codeOf(response), ApiErrorCode.unprocessable);
    });

    test('lit le corps rendu en octets', () {
      final response = _response(
        data: utf8.encode(jsonEncode({'code': 'FORBIDDEN'})),
      );

      expect(ApiErrorParser.codeOf(response), ApiErrorCode.forbidden);
    });

    test('un corps non-JSON ne fait rien exploser', () {
      final response = _response(data: '<html><body>502</body></html>');

      expect(ApiErrorParser.codeOf(response), ApiErrorCode.unknown);
      expect(ApiErrorParser.serverMessageOf(response), isNull);
    });

    test('une réponse absente ne fait rien exploser', () {
      expect(ApiErrorParser.codeOf(null), ApiErrorCode.unknown);
      expect(ApiErrorParser.incidentIdOf(null), isNull);
      expect(ApiErrorParser.retryAfterOf(null), isNull);
    });

    test('un message vide vaut absent', () {
      final response = _response(data: {'message': '   '});

      expect(ApiErrorParser.serverMessageOf(response), isNull);
    });
  });

  group('ApiErrorParser — incidentId', () {
    test('le 500 porte la référence à citer au support', () {
      final response = _response(
        statusCode: 500,
        data: {'code': 'INTERNAL_ERROR', 'incidentId': 'INC-7F2A91'},
      );

      final failure = ApiErrorParser.serverFailure(response);

      expect(failure.incidentId, 'INC-7F2A91');
      expect(failure.code, ApiErrorCode.internalError);
    });

    test('une panne sans référence reste exploitable', () {
      final failure = ApiErrorParser.serverFailure(
        _response(statusCode: 503, data: {'code': 'INTERNAL_ERROR'}),
      );

      expect(failure.incidentId, isNull);
      expect(failure, isA<ServerFailure>());
    });
  });

  group('ApiErrorParser — Retry-After', () {
    test('lit un délai en secondes', () {
      final response = _response(
        statusCode: 429,
        headers: {
          'retry-after': ['30'],
        },
      );

      expect(
        ApiErrorParser.tooManyRequestsFailure(response).retryAfter,
        const Duration(seconds: 30),
      );
    });

    test('une date HTTP est ignorée plutôt que mal lue', () {
      // Un compte à rebours faux serait pire qu'absent : l'écran sait s'en
      // passer, il ne sait pas rattraper un délai inventé.
      final response = _response(
        statusCode: 429,
        headers: {
          'retry-after': ['Wed, 21 Oct 2026 07:28:00 GMT'],
        },
      );

      expect(
        ApiErrorParser.tooManyRequestsFailure(response).retryAfter,
        isNull,
      );
    });
  });

  group('les deux 400 ne se confondent plus', () {
    // C'est la raison d'être de tout ce fichier. Avant, ces deux réponses
    // arrivaient à l'écran sous le même `ValidationFailure('Invalid request
    // data')` — alors que l'une se corrige sur place et que l'autre impose de
    // purger le brouillon et de revenir à l'étape de l'année.
    test('BUSINESS_RULE et VALIDATION sont distinguables', () {
      final businessRule = ApiErrorParser.validationFailure(
        _response(data: {'code': 'BUSINESS_RULE'}),
      );
      final validation = ApiErrorParser.validationFailure(
        _response(data: {'code': 'VALIDATION'}),
      );

      expect(businessRule.code, ApiErrorCode.businessRule);
      expect(validation.code, ApiErrorCode.validation);
      expect(businessRule, isNot(validation));
    });

    test(
      'les deux restent des ValidationFailure pour les appelants existants',
      () {
        // Une vingtaine de repositories filtrent sur ce type. Le sous-typage est
        // exactement ce qui permet d'ajouter le code sans les toucher.
        expect(
          ApiErrorParser.validationFailure(
            _response(data: {'code': 'VALIDATION'}),
          ),
          isA<ValidationFailure>(),
        );
      },
    );
  });
}
