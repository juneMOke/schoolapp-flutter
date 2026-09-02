import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/exchange_rate_remote_data_source.dart';

/// Transport factice : rend le corps voulu et mémorise ce qui part sur le fil.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({this.status = 200, this.body, this.etag});

  final int status;
  final Object? body;
  final String? etag;
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
        if (etag != null) 'etag': <String>[etag!],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Le bundle des taux, lu sur le flux de synchro.
///
/// Ce que ces tests tiennent : la réponse est **enveloppée** (`{points,
/// serverTime}`), et la lire comme une liste racine rendrait une série vide à
/// chaque cycle — sans erreur, sans trace, avec un guichet qui n'aurait jamais
/// de taux. C'est le mode de panne exact que la bascule de devise ne pardonne
/// pas.
void main() {
  ExchangeRateRemoteDataSource sourceOn(_StubAdapter adapter) =>
      ExchangeRateRemoteDataSource(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..httpClientAdapter = adapter,
      );

  Map<String, Object?> point({String depuis = '2026-09-01T06:00:00Z'}) => {
    'id': 'r1',
    'devisePivot': 'USD',
    'deviseRecue': 'CDF',
    'taux': 2800,
    'tolerancePourcent': 2,
    'enVigueurDepuis': depuis,
  };

  test('la série se lit sous `points`, jamais à la racine', () async {
    final adapter = _StubAdapter(
      body: {
        'points': [point()],
        'serverTime': '2026-09-01T10:00:00Z',
      },
      etag: 'W/"v1"',
    );

    final result = await sourceOn(adapter).fetch(const {});

    expect(result.points, hasLength(1));
    expect(result.points.single.devisePivot, 'USD');
    expect(result.etag, 'W/"v1"');
    expect(result.notModified, isFalse);
  });

  test('un corps servi À PLAT LÈVE — il ne se lit pas « aucun taux »', () async {
    // Une série vide et une enveloppe non reconnue se ressemblent — zéro point
    // — mais n'ont pas la même conséquence : la première vide légitimement le
    // cache, la seconde le viderait sur TOUT le parc au premier changement de
    // forme, sans erreur et sans trace. Un cycle en échec, lui, se voit : le
    // cache est conservé et la fraîcheur n'avance pas.
    final adapter = _StubAdapter(body: [point()]);

    expect(
      () => sourceOn(adapter).fetch(const {}),
      throwsA(isA<FormatException>()),
    );
  });

  test('une enveloppe sans `points` lève aussi', () async {
    final adapter = _StubAdapter(body: {'data': const []});

    expect(
      () => sourceOn(adapter).fetch(const {}),
      throwsA(isA<FormatException>()),
    );
  });

  test('l’empreinte connue part en `If-None-Match`', () async {
    final adapter = _StubAdapter(body: {'points': const []});

    await sourceOn(adapter).fetch(const {}, etag: 'W/"v0"');

    expect(adapter.captured?.headers['If-None-Match'], 'W/"v0"');
    expect(adapter.captured?.path, AppConstants.exchangeRatesSyncEndpoint);
  });

  test('sans empreinte connue, aucun en-tête vide n’est envoyé', () async {
    final adapter = _StubAdapter(body: {'points': const []});

    await sourceOn(adapter).fetch(const {});

    expect(adapter.captured?.headers.containsKey('If-None-Match'), isFalse);
  });

  test('304 est une RÉPONSE, pas une panne', () async {
    final adapter = _StubAdapter(status: 304, etag: 'W/"v0"');

    final result = await sourceOn(adapter).fetch(const {}, etag: 'W/"v0"');

    expect(result.notModified, isTrue);
    expect(result.etag, 'W/"v0"');
    expect(
      result.points,
      isEmpty,
      reason:
          'un 304 ne porte pas de corps : c’est au repo de NE PAS confondre '
          'cette liste vide avec « cette école ne publie plus de taux »',
    );
  });

  test('une série vide est une réponse complète, pas un trou', () async {
    final adapter = _StubAdapter(
      body: {'points': const [], 'serverTime': '2026-09-01T10:00:00Z'},
    );

    final result = await sourceOn(adapter).fetch(const {});

    expect(result.points, isEmpty);
    expect(result.notModified, isFalse);
  });

  test('un point illisible s’écarte sans emporter la série', () async {
    final adapter = _StubAdapter(
      body: {
        'points': [
          point(),
          {'devisePivot': 'USD'}, // ni taux ni date : inexploitable
          'pas un objet',
        ],
      },
    );

    final result = await sourceOn(adapter).fetch(const {});

    expect(result.points, hasLength(1));
  });

  test('une panne réseau remonte, elle ne se tait pas', () async {
    final adapter = _StubAdapter(status: 500);

    expect(
      () => sourceOn(adapter).fetch(const {}),
      throwsA(isA<DioException>()),
      reason:
          'le repo la traduit en échec de cycle : un pull muet laisserait la '
          'pastille verte sur un taux périmé',
    );
  });
}
