import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';

void main() {
  final request = RequestOptions(path: '/x');

  test('la valeur passe', () async {
    expect(await guardOnline(() async => 3), const Right<Failure, int>(3));
  });

  test(
    'la Failure rangée par l\'intercepteur est rendue telle quelle',
    () async {
      final result = await guardOnline<int>(
        () => throw DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: 403),
          error: const UnauthorizedFailure(),
        ),
      );
      expect(result, const Left<Failure, int>(UnauthorizedFailure()));
    },
  );

  test('sans réponse : le réseau', () async {
    final result = await guardOnline<int>(
      () => throw DioException(requestOptions: request),
    );
    expect(result, const Left<Failure, int>(NetworkFailure()));
  });

  test('réponse illisible : le serveur, avec la cause', () async {
    final result = await guardOnline<int>(
      () => throw const FormatException('illisible'),
    );
    expect(result, const Left<Failure, int>(ServerFailure('illisible')));
  });
}
