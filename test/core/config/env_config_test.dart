import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/config/env_config.dart';

void main() {
  group('EnvConfig', () {
    test('autorise HTTP en dev', () {
      final config = EnvConfig.forTesting(
        appEnvironment: 'dev',
        apiBaseUrl: 'http://10.0.2.2:8080',
      );

      expect(config.isDevelopment, isTrue);
      expect(config.apiBaseUrl, 'http://10.0.2.2:8080');
    });

    test('refuse HTTP en staging', () {
      expect(
        () => EnvConfig.forTesting(
          appEnvironment: 'staging',
          apiBaseUrl: 'http://staging.api.example.com',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('HTTPS'),
          ),
        ),
      );
    });

    test('refuse HTTP en prod', () {
      expect(
        () => EnvConfig.forTesting(
          appEnvironment: 'prod',
          apiBaseUrl: 'http://api.example.com',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('HTTPS'),
          ),
        ),
      );
    });

    test('autorise HTTPS en staging', () {
      final config = EnvConfig.forTesting(
        appEnvironment: 'staging',
        apiBaseUrl: 'https://staging.api.example.com',
      );

      expect(config.isStaging, isTrue);
      expect(config.apiBaseUrl, 'https://staging.api.example.com');
    });

    test('autorise HTTPS en prod', () {
      final config = EnvConfig.forTesting(
        appEnvironment: 'prod',
        apiBaseUrl: 'https://api.example.com',
      );

      expect(config.isProduction, isTrue);
      expect(config.apiBaseUrl, 'https://api.example.com');
    });
  });
}
