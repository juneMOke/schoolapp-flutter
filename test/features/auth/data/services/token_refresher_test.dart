import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/data/services/token_refresher.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class MockTokenStorageService extends Mock implements TokenStorageService {}

class MockAuthSessionManager extends Mock implements AuthSessionManager {}

/// Adaptateur HTTP factice : compte les appels et renvoie une réponse canned,
/// une erreur 401, ou lève une erreur réseau (timeout).
class _FakeAdapter implements HttpClientAdapter {
  int calls = 0;
  final bool failWith401;
  final bool failWith403Html;
  final bool failWithNetwork;
  _FakeAdapter({
    this.failWith401 = false,
    this.failWith403Html = false,
    this.failWithNetwork = false,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (failWithNetwork) {
      throw DioException.connectionTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: options,
      );
    }
    if (failWith401) {
      // Rejet API : corps d'erreur JSON structuré (content-type json → Dio le
      // décode en Map, ce qui classe la réponse « API » pour la brûlure m4).
      return ResponseBody.fromString(
        '{"message":"refresh token revoked"}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (failWith403Html) {
      // Portail captif / proxy : 403 en HTML — PAS une réponse de notre API.
      return ResponseBody.fromString('<html>hotspot login</html>', 403);
    }
    final body = jsonEncode({
      'accessToken': 'new_access',
      'tokenType': 'Bearer',
      'expiresIn': 3600,
      'refreshToken': 'new_refresh',
      'refreshExpiresIn': 7776000,
      'userVersion': 5,
      'user': {
        'id': 'u1',
        'email': 'u@e.cd',
        'firstName': 'A',
        'lastName': 'B',
        'role': 'TEACHER',
        'schoolId': 's',
      },
    });
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late MockTokenStorageService tokenStorage;
  late MockAuthSessionManager sessionManager;

  setUpAll(() {
    registerFallbackValue(
      const AuthSession(
        accessToken: '',
        tokenType: 'Bearer',
        expiresIn: 0,
        user: AuthenticatedUser(
          email: 'x',
          firstName: 'x',
          lastName: 'x',
          role: 'x',
          schoolId: 'x',
        ),
      ),
    );
  });

  setUp(() {
    tokenStorage = MockTokenStorageService();
    sessionManager = MockAuthSessionManager();
    when(
      () => tokenStorage.readRefreshToken(),
    ).thenAnswer((_) async => 'old_refresh');
    when(() => sessionManager.applyRefresh(any())).thenAnswer((_) async {});
    when(
      () => sessionManager.wipeSession(
        revokeOfflineWindow: any(named: 'revokeOfflineWindow'),
      ),
    ).thenAnswer((_) async {});
  });

  TokenRefresher build(_FakeAdapter adapter) {
    final bareDio = Dio(BaseOptions(baseUrl: 'https://x'))
      ..httpClientAdapter = adapter;
    return TokenRefresher(
      bareDio: bareDio,
      tokenStorage: tokenStorage,
      sessionManager: sessionManager,
      now: () => 1000,
    );
  }

  test(
    'refresh réussi renvoie le nouvel access token et applique la session',
    () async {
      final adapter = _FakeAdapter();
      final refresher = build(adapter);

      final token = await refresher.refresh();

      expect(token, 'new_access');
      verify(() => sessionManager.applyRefresh(any())).called(1);
    },
  );

  test(
    'single-flight : deux refresh concurrents = un seul appel réseau',
    () async {
      final adapter = _FakeAdapter();
      final refresher = build(adapter);

      final results = await Future.wait([
        refresher.refresh(),
        refresher.refresh(),
      ]);

      expect(results, ['new_access', 'new_access']);
      expect(adapter.calls, 1);
    },
  );

  test('refresh rejeté (401) → null + wipe de session', () async {
    final adapter = _FakeAdapter(failWith401: true);
    final refresher = build(adapter);

    final token = await refresher.refresh();

    expect(token, isNull);
    // Refus définitif de l'API → wipe ET fenêtre offline brûlée (m4).
    verify(
      () => sessionManager.wipeSession(revokeOfflineWindow: true),
    ).called(1);
  });

  test(
    'refresh 403 de portail captif (HTML) → wipe SANS brûler la fenêtre',
    () async {
      final adapter = _FakeAdapter(failWith403Html: true);
      final refresher = build(adapter);

      final token = await refresher.refresh();

      expect(token, isNull);
      // Le rejet ne vient pas de notre API : la fenêtre offline (m4) survit —
      // l'agent pourra se reconnecter offline malgré le Wi-Fi sans backhaul.
      verify(
        () => sessionManager.wipeSession(revokeOfflineWindow: false),
      ).called(1);
    },
  );

  test(
    'erreur réseau transitoire → null SANS wipe (B1 : la session survit)',
    () async {
      final adapter = _FakeAdapter(failWithNetwork: true);
      final refresher = build(adapter);

      final token = await refresher.refresh();

      expect(token, isNull);
      verifyNever(
        () => sessionManager.wipeSession(
          revokeOfflineWindow: any(named: 'revokeOfflineWindow'),
        ),
      );
    },
  );

  test('sans refresh token → null sans appel réseau', () async {
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => null);
    final adapter = _FakeAdapter();
    final refresher = build(adapter);

    expect(await refresher.refresh(), isNull);
    expect(adapter.calls, 0);
  });
}
