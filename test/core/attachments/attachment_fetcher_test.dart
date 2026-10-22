import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/attachments/attachment_fetcher.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/attachments/ephemeral_attachment_cache.dart';

class _Dio extends Mock implements Dio {}

void main() {
  const ref = AttachmentRef(
    name: 'certificat.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 3,
    sha256: 'abc',
  );
  final bytes = Uint8List.fromList([1, 2, 3]);
  late _Dio dio;
  late EphemeralAttachmentCache cache;
  late AttachmentFetcher fetcher;

  Response<List<int>> response(int status, [List<int>? data]) => Response(
    requestOptions: RequestOptions(path: '/file'),
    statusCode: status,
    data: data,
  );

  Future<AttachmentFetch> fetch() =>
      fetcher.fetch(path: '/file', ref: ref, extras: const {});

  Options captured() =>
      verify(
            () => dio.get<List<int>>(
              '/file',
              options: captureAny(named: 'options'),
            ),
          ).captured.single
          as Options;

  setUp(() {
    dio = _Dio();
    cache = EphemeralAttachmentCache(inMemory: true);
    fetcher = AttachmentFetcher(dio, cache);
  });

  test('200 : les octets sont rendus et gardés pour la session', () async {
    when(
      () => dio.get<List<int>>(any(), options: any(named: 'options')),
    ).thenAnswer((_) async => response(200, bytes));

    final result = await fetch();

    expect((result as AttachmentFetched).bytes, bytes);
    expect(await fetcher.isCached(ref), isTrue);
    expect(captured().headers, isNot(contains('If-None-Match')));
  });

  test('déjà là : revalidée par If-None-Match, et 304 la rend', () async {
    await cache.write('abc', bytes);
    when(
      () => dio.get<List<int>>(any(), options: any(named: 'options')),
    ).thenAnswer((_) async => response(304));

    final result = await fetch();

    expect((result as AttachmentFetched).bytes, bytes);
    expect(captured().headers?['If-None-Match'], '"abc"');
  });

  test('hors connexion : la pièce déjà là est rendue', () async {
    await cache.write('abc', bytes);
    when(
      () => dio.get<List<int>>(any(), options: any(named: 'options')),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '/file')));

    expect(await fetch(), isA<AttachmentFetched>());
  });

  test('hors connexion sans la pièce : « hors ligne »', () async {
    when(
      () => dio.get<List<int>>(any(), options: any(named: 'options')),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '/file')));

    final result = await fetch();

    expect(
      (result as AttachmentFetchFailed).error,
      AttachmentFetchError.offline,
    );
  });

  test(
    'refus du serveur : « indisponible », même avec la pièce en cache',
    () async {
      await cache.write('abc', bytes);
      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/file'),
          response: Response(
            requestOptions: RequestOptions(path: '/file'),
            statusCode: 403,
          ),
        ),
      );

      final result = await fetch();

      expect(
        (result as AttachmentFetchFailed).error,
        AttachmentFetchError.unavailable,
      );
    },
  );
}
