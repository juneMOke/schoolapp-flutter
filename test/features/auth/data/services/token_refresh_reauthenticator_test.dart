import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/data/services/token_refresh_reauthenticator.dart';
import 'package:school_app_flutter/features/auth/data/services/token_refresher.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class MockTokenStorageService extends Mock implements TokenStorageService {}

class MockTokenRefresher extends Mock implements TokenRefresher {}

const _user = AuthenticatedUser(
  id: 'u1',
  email: 'u@e.cd',
  firstName: 'A',
  lastName: 'B',
  role: 'TEACHER',
  schoolId: 's1',
);

AuthSession _session({required String accessToken, int? accessExpiresAt}) =>
    AuthSession(
      accessToken: accessToken,
      tokenType: 'Bearer',
      expiresIn: 3600,
      refreshToken: 'r1',
      accessExpiresAt: accessExpiresAt,
      user: _user,
    );

void main() {
  late MockTokenStorageService storage;
  late MockTokenRefresher refresher;

  const nowMs = 1_000_000;

  setUp(() {
    storage = MockTokenStorageService();
    refresher = MockTokenRefresher();
  });

  TokenRefreshReauthenticator build() => TokenRefreshReauthenticator(
    tokenStorage: storage,
    refresher: refresher,
    now: () => nowMs,
  );

  test('access valide → true SANS appel réseau', () async {
    when(() => storage.readAuthSession()).thenAnswer(
      (_) async => _session(
        accessToken: 'live',
        accessExpiresAt: nowMs + const Duration(minutes: 10).inMilliseconds,
      ),
    );

    expect(await build().ensureFreshAccess(), isTrue);
    verifyNever(() => refresher.refresh());
  });

  test(
    'access vide (session ouverte offline) → mint, true si réussi',
    () async {
      when(
        () => storage.readAuthSession(),
      ).thenAnswer((_) async => _session(accessToken: ''));
      when(() => refresher.refresh()).thenAnswer((_) async => 'fresh');

      expect(await build().ensureFreshAccess(), isTrue);
      verify(() => refresher.refresh()).called(1);
    },
  );

  test('access périmé → mint', () async {
    when(() => storage.readAuthSession()).thenAnswer(
      (_) async => _session(accessToken: 'stale', accessExpiresAt: nowMs - 1),
    );
    when(() => refresher.refresh()).thenAnswer((_) async => 'fresh');

    expect(await build().ensureFreshAccess(), isTrue);
    verify(() => refresher.refresh()).called(1);
  });

  test('access expirant dans la marge de sécurité → mint d\'avance', () async {
    // 10 s de reste : le jeton mourrait au milieu du flush qu'il couvre.
    when(() => storage.readAuthSession()).thenAnswer(
      (_) async => _session(
        accessToken: 'almost',
        accessExpiresAt: nowMs + const Duration(seconds: 10).inMilliseconds,
      ),
    );
    when(() => refresher.refresh()).thenAnswer((_) async => 'fresh');

    expect(await build().ensureFreshAccess(), isTrue);
    verify(() => refresher.refresh()).called(1);
  });

  test('mint impossible → false (l\'appelant ne doit rien tenter)', () async {
    when(
      () => storage.readAuthSession(),
    ).thenAnswer((_) async => _session(accessToken: ''));
    when(() => refresher.refresh()).thenAnswer((_) async => null);

    expect(await build().ensureFreshAccess(), isFalse);
  });

  test('aucune session en storage → tente un mint puis false', () async {
    when(() => storage.readAuthSession()).thenAnswer((_) async => null);
    when(() => refresher.refresh()).thenAnswer((_) async => null);

    expect(await build().ensureFreshAccess(), isFalse);
  });

  test('borne d\'expiration absente → jeton accepté tel quel', () async {
    when(
      () => storage.readAuthSession(),
    ).thenAnswer((_) async => _session(accessToken: 'live'));

    expect(await build().ensureFreshAccess(), isTrue);
    verifyNever(() => refresher.refresh());
  });

  test('storage indisponible → false, jamais d\'exception', () async {
    when(() => storage.readAuthSession()).thenThrow(Exception('keystore down'));

    expect(await build().ensureFreshAccess(), isFalse);
  });
}
