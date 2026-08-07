import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:school_app_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockAuthSessionManager extends Mock implements AuthSessionManager {}

const _user = AuthenticatedUser(
  id: 'u1',
  email: 'u@e.cd',
  firstName: 'A',
  lastName: 'B',
  role: 'TEACHER',
  schoolId: 's1',
);

/// JWT non signé (le device ne vérifie pas la signature, ADR-010 §0.2) dont
/// seul le claim `exp` compte ici.
String _jwt({required int expSeconds}) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${seg({'alg': 'HS256'})}.${seg({'exp': expSeconds})}.sig';
}

void main() {
  late MockAuthRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late MockAuthSessionManager sessionManager;

  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  setUp(() {
    remote = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    sessionManager = MockAuthSessionManager();
  });

  AuthRepositoryImpl build() => AuthRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    sessionManager: sessionManager,
  );

  void stubSession(AuthSession? session) {
    when(() => local.getSession()).thenAnswer((_) async => session);
  }

  Future<bool> isAuthenticated() async =>
      (await build().isAuthenticated()).getOrElse(() => false);

  test('access valide → authentifié', () async {
    stubSession(
      AuthSession(
        accessToken: _jwt(expSeconds: nowSeconds + 3600),
        tokenType: 'Bearer',
        expiresIn: 3600,
        user: _user,
      ),
    );

    expect(await isAuthenticated(), isTrue);
  });

  test(
    'access VIDE (session ouverte offline) + refresh vivant → authentifié',
    () async {
      // Régression : au redémarrage, l'agent était renvoyé sur l'écran de
      // connexion alors que son refresh token était là, valide, et suffisait à
      // minter un access au premier appel.
      stubSession(
        AuthSession(
          accessToken: '',
          tokenType: 'Bearer',
          expiresIn: 0,
          refreshToken: 'r1',
          refreshExpiresAt: nowMs + const Duration(days: 3).inMilliseconds,
          user: _user,
        ),
      );

      expect(await isAuthenticated(), isTrue);
    },
  );

  test('access PÉRIMÉ + refresh vivant → authentifié', () async {
    stubSession(
      AuthSession(
        accessToken: _jwt(expSeconds: nowSeconds - 60),
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshToken: 'r1',
        refreshExpiresAt: nowMs + const Duration(days: 3).inMilliseconds,
        user: _user,
      ),
    );

    expect(await isAuthenticated(), isTrue);
  });

  test('access périmé + refresh PÉRIMÉ → non authentifié', () async {
    stubSession(
      AuthSession(
        accessToken: _jwt(expSeconds: nowSeconds - 60),
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshToken: 'r1',
        refreshExpiresAt: nowMs - 1,
        user: _user,
      ),
    );

    expect(await isAuthenticated(), isFalse);
  });

  test(
    'access périmé SANS refresh → non authentifié (rien à minter)',
    () async {
      // Invariant ADR-010 : après un logout/une révocation, les jetons sont
      // effacés — la consigne verrouillée par mot de passe n'est pas lue ici.
      stubSession(
        const AuthSession(
          accessToken: '',
          tokenType: 'Bearer',
          expiresIn: 0,
          user: _user,
        ),
      );

      expect(await isAuthenticated(), isFalse);
    },
  );

  test('borne refresh absente → le refresh fait foi', () async {
    stubSession(
      const AuthSession(
        accessToken: '',
        tokenType: 'Bearer',
        expiresIn: 0,
        refreshToken: 'r1',
        user: _user,
      ),
    );

    expect(await isAuthenticated(), isTrue);
  });

  test('aucune session → non authentifié', () async {
    stubSession(null);

    expect(await isAuthenticated(), isFalse);
  });

  test('storage indisponible → Left(StorageFailure)', () async {
    when(() => local.getSession()).thenThrow(Exception('keystore down'));

    final result = await build().isAuthenticated();

    expect(result.isLeft(), isTrue);
  });
}
