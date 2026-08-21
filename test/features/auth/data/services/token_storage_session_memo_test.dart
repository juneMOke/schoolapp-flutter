import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// B-6 — un tic de battement qui a du travail prêt lit la session **quatre
/// fois** : sonde de crédentiels, ré-authentificateur, garde propre du moteur,
/// puis refresh. Chaque lecture, c'était treize allers-retours MethodChannel et
/// autant de déchiffrements Keystore — une cinquantaine toutes les 45 secondes.
///
/// Ce qui porte la correction n'est pas le délai mais **l'invalidation** : le
/// mémo vit dans la classe qui détient toutes les écritures de ces clés, donc
/// un mint qui vient de réécrire l'access est vu par la garde suivante.
void main() {
  late _MockSecureStorage storage;
  late Map<String, String?> values;
  late int reads;
  late int clock;

  AuthSession session({String accessToken = 'jwt-1'}) => AuthSession(
    accessToken: accessToken,
    tokenType: 'Bearer',
    expiresIn: 3600,
    refreshToken: 'refresh',
    accessExpiresAt: 5000,
    refreshExpiresAt: 9000,
    user: const AuthenticatedUser(
      id: 'u1',
      email: 'prof@ecole.cd',
      firstName: 'Amina',
      lastName: 'Kalala',
      role: 'TEACHER',
      schoolId: 'sch-1',
    ),
  );

  TokenStorageService serviceUnderTest() =>
      TokenStorageService(storage, now: () => clock);

  setUp(() {
    clock = 0;
    reads = 0;
    values = <String, String?>{
      AppConstants.accessTokenKey: 'jwt-1',
      AppConstants.tokenTypeKey: 'Bearer',
      AppConstants.expiresInKey: '3600',
      AppConstants.refreshTokenKey: 'refresh',
      AppConstants.accessExpiresAtKey: '5000',
      AppConstants.refreshExpiresAtKey: '9000',
      AppConstants.userIdKey: 'u1',
    };
    storage = _MockSecureStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((invocation) {
      reads++;
      return Future<String?>.value(
        values[invocation.namedArguments[#key] as String],
      );
    });
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((invocation) async {
      values[invocation.namedArguments[#key] as String] =
          invocation.namedArguments[#value] as String?;
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((
      invocation,
    ) async {
      values.remove(invocation.namedArguments[#key] as String);
    });
  });

  test(
    'quatre lectures d\'un même tic ne paient qu\'un seul déchiffrement',
    () async {
      final service = serviceUnderTest();

      await service.readAuthSession();
      final afterFirst = reads;
      await service.readAuthSession();
      await service.readAuthSession();
      await service.readAuthSession();

      expect(afterFirst, greaterThan(1), reason: 'la 1re lecture paie le prix');
      expect(
        reads,
        afterFirst,
        reason: 'les trois suivantes ne touchent plus le Keystore',
      );
    },
  );

  test('une session ABSENTE est mémorisée comme le reste', () async {
    // Chemin le plus fréquent du parc hors ligne : sans access, il n'y a rien à
    // composer, et treize allers-retours pour rien coûtent le plus cher.
    values.remove(AppConstants.accessTokenKey);
    final service = serviceUnderTest();

    expect(await service.readAuthSession(), isNull);
    final afterFirst = reads;
    expect(await service.readAuthSession(), isNull);

    expect(reads, afterFirst);
  });

  group('invalidation — c\'est elle qui porte la correction', () {
    test('un mint (updateTokens) est vu par la lecture suivante', () async {
      // Le cas qui interdit de se reposer sur le seul délai : le
      // ré-authentificateur renouvelle l'access, et la garde du moteur lit un
      // dixième de seconde plus tard. Servir l'ancien jeton ferait sauter le
      // flush que le mint venait d'autoriser.
      final service = serviceUnderTest();
      expect((await service.readAuthSession())?.accessToken, 'jwt-1');

      await service.updateTokens(session(accessToken: 'jwt-2'));

      expect((await service.readAuthSession())?.accessToken, 'jwt-2');
    });

    test('une ouverture de session (saveAuthSession) aussi', () async {
      final service = serviceUnderTest();
      await service.readAuthSession();

      await service.saveAuthSession(session(accessToken: 'jwt-3'));

      expect((await service.readAuthSession())?.accessToken, 'jwt-3');
    });

    test('un wipe (clearAuthSession) aussi', () async {
      final service = serviceUnderTest();
      await service.readAuthSession();

      await service.clearAuthSession();

      expect(await service.readAuthSession(), isNull);
    });
  });

  test(
    'le délai plafonne la péremption d\'une écriture venue d\'ailleurs',
    () async {
      // Filet, pas mécanisme : aucune autre classe n'écrit ces clés aujourd'hui.
      // Si l'une apparaissait, la péremption durerait quelques secondes, pas la
      // vie du processus.
      final service = serviceUnderTest();
      await service.readAuthSession();

      values[AppConstants.accessTokenKey] = 'jwt-hors-service';
      expect(
        (await service.readAuthSession())?.accessToken,
        'jwt-1',
        reason: 'le mémo tient tant que le délai court',
      );

      clock = 3001;

      expect(
        (await service.readAuthSession())?.accessToken,
        'jwt-hors-service',
      );
    },
  );
}
