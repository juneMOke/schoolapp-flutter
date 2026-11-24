import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/storage/desktop_environment_scope.dart';
import 'package:school_app_flutter/core/storage/env_scoped_secure_storage.dart';
import 'package:school_app_flutter/core/storage/serialized_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Un seul trousseau pour tout le poste, comme le greffon desktop : la
  // production y a déjà sa session et sa clé de base.
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'jeton-prod',
      'sqlcipher_device_key': 'cle-prod',
    });
  });

  group('desktopIsolatedEnvironment', () {
    test('la production n’est jamais isolée', () {
      for (final platform in [TargetPlatform.linux, TargetPlatform.windows]) {
        expect(
          desktopIsolatedEnvironment(platform: platform, environment: 'prod'),
          isNull,
        );
        expect(
          desktopIsolatedEnvironment(
            platform: platform,
            environment: 'production',
          ),
          isNull,
        );
      }
    });

    test('staging et dev sont isolés sur le poste', () {
      expect(
        desktopIsolatedEnvironment(
          platform: TargetPlatform.linux,
          environment: 'staging',
        ),
        'staging',
      );
      expect(
        desktopIsolatedEnvironment(
          platform: TargetPlatform.windows,
          environment: 'dev',
        ),
        'dev',
      );
    });

    test('la tablette n’est jamais isolée (une application par flavor)', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        expect(
          desktopIsolatedEnvironment(
            platform: platform,
            environment: 'staging',
          ),
          isNull,
        );
      }
    });
  });

  group('createAppSecureStorage', () {
    test('production : le greffon tel quel, clés inchangées', () async {
      final linux = createAppSecureStorage(
        platform: TargetPlatform.linux,
        isolatedEnvironment: null,
      );
      expect(linux, isNot(isA<EnvScopedSecureStorage>()));
      expect(await linux.read(key: 'auth_token'), 'jeton-prod');

      final windows = createAppSecureStorage(
        platform: TargetPlatform.windows,
        isolatedEnvironment: null,
      );
      expect(windows, isA<SerializedSecureStorage>());
      expect(await windows.read(key: 'sqlcipher_device_key'), 'cle-prod');
    });

    test('staging : préfixé, et toujours sérialisé sous Windows', () async {
      final windows = createAppSecureStorage(
        platform: TargetPlatform.windows,
        isolatedEnvironment: 'staging',
      );
      expect(windows, isA<EnvScopedSecureStorage>());
      await windows.write(key: 'auth_token', value: 'jeton-staging');
      expect(await windows.read(key: 'auth_token'), 'jeton-staging');
    });
  });

  group('EnvScopedSecureStorage', () {
    const prod = FlutterSecureStorage();

    test('la staging ne lit pas les entrées de la production', () async {
      final staging = EnvScopedSecureStorage(prod, environment: 'staging');
      expect(await staging.read(key: 'auth_token'), isNull);
      expect(await staging.containsKey(key: 'sqlcipher_device_key'), isFalse);
    });

    test('une écriture de la staging laisse la production intacte', () async {
      final staging = EnvScopedSecureStorage(prod, environment: 'staging');
      await staging.write(key: 'auth_token', value: 'jeton-staging');

      expect(await staging.read(key: 'auth_token'), 'jeton-staging');
      expect(await prod.read(key: 'auth_token'), 'jeton-prod');
      expect(await prod.read(key: 'staging::auth_token'), 'jeton-staging');
    });

    test('staging et dev ne se voient pas', () async {
      final staging = EnvScopedSecureStorage(prod, environment: 'staging');
      final dev = EnvScopedSecureStorage(prod, environment: 'dev');
      await staging.write(key: 'k', value: 's');
      await dev.write(key: 'k', value: 'd');
      expect(await staging.read(key: 'k'), 's');
      expect(await dev.read(key: 'k'), 'd');
    });

    test(
      'readAll ne rend que les entrées de l’environnement, sans préfixe',
      () async {
        final staging = EnvScopedSecureStorage(prod, environment: 'staging');
        await staging.write(key: 'auth_token', value: 'jeton-staging');
        expect(await staging.readAll(), {'auth_token': 'jeton-staging'});
      },
    );

    test('deleteAll n’efface jamais la production', () async {
      final staging = EnvScopedSecureStorage(prod, environment: 'staging');
      await staging.write(key: 'auth_token', value: 'jeton-staging');
      await staging.deleteAll();

      expect(await staging.readAll(), isEmpty);
      expect(await prod.readAll(), {
        'auth_token': 'jeton-prod',
        'sqlcipher_device_key': 'cle-prod',
      });
    });

    test('delete ne touche que la clé préfixée', () async {
      final staging = EnvScopedSecureStorage(prod, environment: 'staging');
      await staging.write(key: 'auth_token', value: 'jeton-staging');
      await staging.delete(key: 'auth_token');
      expect(await staging.read(key: 'auth_token'), isNull);
      expect(await prod.read(key: 'auth_token'), 'jeton-prod');
    });
  });

  group('blobBaseDirectoryPath', () {
    Future<String> support() async => '/support';

    test('production : la racine du dossier de support, comme avant', () async {
      expect(
        await blobBaseDirectoryPath(supportDirectory: support),
        '/support',
      );
    });

    test('hors production : un sous-dossier par environnement', () async {
      expect(
        await blobBaseDirectoryPath(
          supportDirectory: support,
          isolatedEnvironment: 'staging',
        ),
        '/support/environments/staging',
      );
    });
  });
}
