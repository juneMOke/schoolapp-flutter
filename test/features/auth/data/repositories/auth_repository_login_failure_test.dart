import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:school_app_flutter/features/auth/data/models/login_request_model.dart';
import 'package:school_app_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockLocal extends Mock implements AuthLocalDataSource {}

class _MockSessionManager extends Mock implements AuthSessionManager {}

final _options = RequestOptions(path: '/auth/login');

void main() {
  late _MockRemote remote;
  late AuthRepositoryImpl repository;

  setUpAll(
    () => registerFallbackValue(
      const LoginRequestModel(email: 'a@b.cd', password: 'x'),
    ),
  );

  setUp(() {
    remote = _MockRemote();
    repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _MockLocal(),
      sessionManager: _MockSessionManager(),
    );
  });

  Future<Failure> loginFailure(Object thrown) async {
    when(() => remote.login(any())).thenThrow(thrown);
    final result = await repository.login(
      email: 'directeur@ecole.cd',
      password: 'secret',
    );
    return result.fold((failure) => failure, (_) => fail('login a réussi'));
  }

  group('le serveur n\'a pas répondu → repli offline autorisé', () {
    // Le bloc ne tente le login offline que sur `NetworkFailure`. Tout ce qui
    // sort d'ici en `ServerFailure` ferme le repli — sur une tablette hors
    // ligne, l'agent voit « Erreur serveur » et ne peut plus travailler.
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.badCertificate,
      DioExceptionType.unknown,
    ]) {
      test('$type sans réponse', () async {
        expect(
          await loginFailure(
            DioException(requestOptions: _options, type: type),
          ),
          isA<NetworkFailure>(),
          reason: '$type',
        );
      });
    }

    test(
      'un `unknown` qui emballe autre chose qu\'une SocketException',
      () async {
        // C'est le cas qui manquait : la liste blanche exigeait une
        // `SocketException`, et une exception de plateforme — ou une
        // `HandshakeException` — tombait en « Erreur serveur ».
        expect(
          await loginFailure(
            DioException(
              requestOptions: _options,
              type: DioExceptionType.unknown,
              error: StateError('adapter blew up'),
            ),
          ),
          isA<NetworkFailure>(),
        );
      },
    );

    test('une SocketException remontée nue', () async {
      expect(
        await loginFailure(const SocketException('no route to host')),
        isA<NetworkFailure>(),
      );
    });
  });

  group('la passerelle a répondu à la place du back → repli offline', () {
    // Cas de terrain : back arrêté, réseau intact, un nginx devant qui rend
    // 502. Le serveur « répond » au sens HTTP, mais l'application est
    // injoignable — pour l'agent c'est un câble arraché, et son travail hors
    // ligne doit rester accessible.
    for (final status in [502, 503, 504]) {
      test('$status', () async {
        expect(
          await loginFailure(
            DioException(
              requestOptions: _options,
              response: Response<dynamic>(
                requestOptions: _options,
                statusCode: status,
              ),
              // L'interceptor a déjà posé sa panne : elle ne doit pas primer
              // sur le fait que la passerelle n'a joint personne.
              error: const ApiServerFailure(incidentId: 'INC-9'),
              type: DioExceptionType.badResponse,
            ),
          ),
          isA<NetworkFailure>(),
          reason: 'HTTP $status',
        );
      });
    }

    test('le 500 reste une panne serveur', () async {
      // Là, l'application a répondu ELLE-MÊME : elle est joignable, et son
      // refus n'est pas un cas de repli.
      final failure = await loginFailure(
        DioException(
          requestOptions: _options,
          response: Response<dynamic>(
            requestOptions: _options,
            statusCode: 500,
          ),
          error: const ApiServerFailure(incidentId: 'INC-1'),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure, isNot(isA<NetworkFailure>()));
    });
  });

  group('le serveur a répondu → jamais de repli', () {
    test('un 429 garde la panne que l\'interceptor a posée', () async {
      // Basculer offline sur un rate-limit contournerait exactement ce que le
      // serveur vient de refuser.
      final failure = await loginFailure(
        DioException(
          requestOptions: _options,
          response: Response<dynamic>(
            requestOptions: _options,
            statusCode: 429,
          ),
          error: const TooManyRequestsFailure(),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(failure, isA<TooManyRequestsFailure>());
      expect(failure, isNot(isA<NetworkFailure>()));
    });

    test('un statut non mappé reste une panne serveur', () async {
      expect(
        await loginFailure(
          DioException(
            requestOptions: _options,
            response: Response<dynamic>(
              requestOptions: _options,
              statusCode: 418,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
        isA<ServerFailure>(),
      );
    });

    test('une annulation ne dit rien du réseau', () async {
      expect(
        await loginFailure(
          DioException(requestOptions: _options, type: DioExceptionType.cancel),
        ),
        isNot(isA<NetworkFailure>()),
      );
    });
  });
}
