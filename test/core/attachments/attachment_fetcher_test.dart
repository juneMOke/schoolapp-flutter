import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/attachments/attachment_fetcher.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/attachments/ephemeral_attachment_cache.dart';

class _Dio extends Mock implements Dio {}

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);
  // sha256 de [1, 2, 3].
  const sha =
      '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81';
  const ref = AttachmentRef(
    name: 'certificat.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 3,
    sha256: sha,
  );
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
    await cache.write(sha, bytes);
    when(
      () => dio.get<List<int>>(any(), options: any(named: 'options')),
    ).thenAnswer((_) async => response(304));

    final result = await fetch();

    expect((result as AttachmentFetched).bytes, bytes);
    expect(captured().headers?['If-None-Match'], '"$sha"');
  });

  test('hors connexion : la pièce déjà là est rendue', () async {
    await cache.write(sha, bytes);
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
      await cache.write(sha, bytes);
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

  test(
    'des octets qui ne portent pas l empreinte ne sont jamais rendus',
    () async {
      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenAnswer((_) async => response(200, [9, 9, 9]));

      final result = await fetch();

      expect(
        (result as AttachmentFetchFailed).error,
        AttachmentFetchError.unavailable,
      );
      expect(await fetcher.isCached(ref), isFalse);
    },
  );

  test('un fichier altéré dans le cache n est ni rendu ni revalidé', () async {
    await cache.write(sha, Uint8List.fromList([6, 6, 6]));
    expect(await fetcher.isCached(ref), isFalse);
    when(
      () => dio.get<List<int>>(any(), options: any(named: 'options')),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '/file')));

    final result = await fetch();

    expect(
      (result as AttachmentFetchFailed).error,
      AttachmentFetchError.offline,
    );
  });
}
