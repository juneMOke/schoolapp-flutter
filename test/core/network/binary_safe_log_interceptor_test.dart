import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/network/binary_safe_log_interceptor.dart';

RequestOptions _options() => RequestOptions(path: '/api/v1/whatever');

Response<dynamic> _response(Object? data, {String? contentType}) {
  return Response<dynamic>(
    requestOptions: _options(),
    statusCode: 200,
    data: data,
    headers: Headers.fromMap(<String, List<String>>{
      if (contentType != null) Headers.contentTypeHeader: <String>[contentType],
    }),
  );
}

/// Un PDF plausible : assez d'octets pour que leur impression brute saute aux
/// yeux dans le journal.
Uint8List _pdfBytes() =>
    Uint8List.fromList(List<int>.generate(4096, (i) => i % 256));

void main() {
  late List<String> lines;
  late BinarySafeLogInterceptor interceptor;

  setUp(() {
    lines = <String>[];
    interceptor = BinarySafeLogInterceptor(
      logPrint: (object) => lines.add(object.toString()),
    );
  });

  String output() => lines.join('\n');

  group('réponses binaires', () {
    test('résume le corps au lieu de le déverser', () {
      interceptor.onResponse(
        _response(_pdfBytes(), contentType: 'application/pdf'),
        ResponseInterceptorHandler(),
      );

      expect(output(), contains('corps binaire non journalisé'));
      expect(output(), contains('4096 octets'));
      expect(output(), contains('application/pdf'));
      // La preuve directe : aucune séquence d'entiers bruts n'a été imprimée.
      expect(output(), isNot(contains('[0, 1, 2, 3')));
    });

    test('reste borné même sur un corps volumineux', () {
      interceptor.onResponse(
        _response(Uint8List(2 * 1024 * 1024), contentType: 'application/pdf'),
        ResponseInterceptorHandler(),
      );

      expect(output().length, lessThan(2000));
    });

    test('résume aussi un corps binaire porté par une erreur', () async {
      final dio = _dioWith(interceptor, _FakeAdapter(statusCode: 404));

      await expectLater(
        dio.post<Uint8List>(
          '/api/v1/whatever',
          options: Options(responseType: ResponseType.bytes),
        ),
        throwsA(isA<DioException>()),
      );

      expect(output(), contains('corps binaire non journalisé'));
      expect(output().length, lessThan(2000));
    });

    test('mentionne un type inconnu quand le content-type est absent', () {
      interceptor.onResponse(
        _response(Uint8List(8)),
        ResponseInterceptorHandler(),
      );

      expect(output(), contains('type inconnu'));
    });
  });

  group('réponses non binaires', () {
    test('journalise normalement un corps JSON', () {
      interceptor.onResponse(
        _response(<String, dynamic>{
          'id': 'abc',
        }, contentType: 'application/json'),
        ResponseInterceptorHandler(),
      );

      expect(output(), contains('abc'));
      expect(output(), isNot(contains('corps binaire')));
    });

    test('journalise le statut et l uri', () {
      interceptor.onResponse(
        _response('ok', contentType: 'text/plain'),
        ResponseInterceptorHandler(),
      );

      expect(output(), contains('statusCode: 200'));
      expect(output(), contains('/api/v1/whatever'));
    });
  });

  // Traversée réelle de la chaîne Dio : c'est le seul moyen de prouver que
  // l'assainissement du journal ne touche pas les octets rendus à l'appelant.
  group('propagation à travers Dio', () {
    test('rend les octets intacts tout en résumant le journal', () async {
      final dio = _dioWith(interceptor, _FakeAdapter());

      final response = await dio.post<Uint8List>(
        '/api/v1/whatever',
        options: Options(responseType: ResponseType.bytes),
      );

      expect(response.data, isA<Uint8List>());
      expect(response.data!.length, 4096);
      expect(response.data, _pdfBytes());
      expect(output(), contains('corps binaire non journalisé'));
      expect(output(), isNot(contains('[0, 1, 2, 3')));
    });

    test('journalise la requête et la réponse sans rien altérer', () async {
      final dio = _dioWith(interceptor, _FakeAdapter());

      await dio.post<Uint8List>(
        '/api/v1/whatever',
        options: Options(responseType: ResponseType.bytes),
      );

      expect(output(), contains('*** Request ***'));
      expect(output(), contains('*** Response ***'));
      expect(output(), contains('/api/v1/whatever'));
    });
  });
}

Dio _dioWith(Interceptor interceptor, HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter
    ..interceptors.add(interceptor);
}

/// Transport factice rendant toujours un corps binaire de 4096 octets.
class _FakeAdapter implements HttpClientAdapter {
  final int statusCode;

  _FakeAdapter({this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      _pdfBytes(),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/pdf'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
