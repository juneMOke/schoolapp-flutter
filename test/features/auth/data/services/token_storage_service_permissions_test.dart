import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

/// Persistance des permissions de la session ACTIVE (ADR-014 §4), exercée sur le
/// faux en mémoire du paquet `flutter_secure_storage` — donc sur le vrai
/// service, pas sur un double.
AuthSession _session({
  List<String> permissions = const <String>[],
  String accessToken = 'jwt',
}) => AuthSession(
  accessToken: accessToken,
  tokenType: 'Bearer',
  expiresIn: 3600,
  refreshToken: 'refresh',
  accessExpiresAt: 5000,
  refreshExpiresAt: 9000,
  userVersion: 3,
  permissions: permissions,
  user: const AuthenticatedUser(
    id: 'u1',
    email: 'prof@ecole.cd',
    firstName: 'Amina',
    lastName: 'Kalala',
    role: 'TEACHER',
    schoolId: 'sch-1',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> stored;
  late TokenStorageService service;

  setUp(() {
    stored = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(stored);
    service = const TokenStorageService(FlutterSecureStorage());
  });

  test('les permissions survivent au save → read', () async {
    await service.saveAuthSession(
      _session(permissions: const ['attendance.read', 'classroom.read']),
    );

    final restored = await service.readAuthSession();
    expect(restored?.permissions, <String>[
      'attendance.read',
      'classroom.read',
    ]);
  });

  test('session stockée avant ADR-014 (clé absente) → ensemble vide', () async {
    await service.saveAuthSession(_session());
    stored.remove(AppConstants.userPermissionsKey);

    expect((await service.readAuthSession())?.permissions, isEmpty);
  });

  test(
    'updateTokens écrase les permissions par le dernier mot du serveur',
    () async {
      await service.saveAuthSession(
        _session(permissions: const ['attendance.read', 'finance.write']),
      );

      await service.updateTokens(
        _session(accessToken: 'jwt-2', permissions: const ['attendance.read']),
      );

      final restored = await service.readAuthSession();
      expect(restored?.accessToken, 'jwt-2');
      expect(restored?.permissions, <String>['attendance.read']);
    },
  );

  test('updateTokens applique un RETRAIT total de droits', () async {
    // Le refresh est le seul canal par lequel un retrait redescend : préserver
    // l'ancien ensemble laisserait un compte dépouillé afficher ses modules.
    await service.saveAuthSession(
      _session(permissions: const ['attendance.read']),
    );

    await service.updateTokens(_session(accessToken: 'jwt-2'));

    expect((await service.readAuthSession())?.permissions, isEmpty);
  });

  test('clearAuthSession efface aussi les permissions', () async {
    await service.saveAuthSession(
      _session(permissions: const ['attendance.read']),
    );

    await service.clearAuthSession();

    expect(stored.containsKey(AppConstants.userPermissionsKey), isFalse);
    expect(await service.readAuthSession(), isNull);
  });
}
