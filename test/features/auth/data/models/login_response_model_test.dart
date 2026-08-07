import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/data/models/login_response_model.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';

void main() {
  group('LoginResponseModel', () {
    const tJson = <String, dynamic>{
      'accessToken': 'test_access_token',
      'tokenType': 'Bearer',
      'expiresIn': 3600,
      'refreshToken': 'test_refresh_token',
      'refreshExpiresIn': 7776000,
      'userVersion': 2,
      'user': <String, dynamic>{
        'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'email': 'user@example.com',
        'firstName': 'John',
        'lastName': 'Doe',
        'role': 'ADMIN',
        'schoolId': '8a9e5f7b-7f8f-4e39-9f89-c0744c5c9f20',
        'createdAt': '2026-03-27T16:57:27.393Z',
      },
    };

    test('fromJson maps all fields correctly', () {
      final model = LoginResponseModel.fromJson(tJson);

      expect(model.accessToken, 'test_access_token');
      expect(model.tokenType, 'Bearer');
      expect(model.expiresIn, 3600);
      expect(model.refreshToken, 'test_refresh_token');
      expect(model.refreshExpiresIn, 7776000);
      expect(model.userVersion, 2);
      expect(model.user.id, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(model.user.email, 'user@example.com');
      expect(model.user.firstName, 'John');
      expect(model.user.lastName, 'Doe');
      expect(model.user.role, 'ADMIN');
      expect(model.user.schoolId, '8a9e5f7b-7f8f-4e39-9f89-c0744c5c9f20');
    });

    test('fromJson tolère un contrat hérité (sans refresh/userVersion)', () {
      final model = LoginResponseModel.fromJson(const <String, dynamic>{
        'accessToken': 'a',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'user': <String, dynamic>{
          'email': 'u@e.cd',
          'firstName': 'A',
          'lastName': 'B',
          'role': 'TEACHER',
          'schoolId': 's',
        },
      });
      expect(model.refreshToken, isNull);
      expect(model.refreshExpiresIn, isNull);
      expect(model.userVersion, 0);
      expect(model.user.id, '');
    });

    test('toAuthSession converts model to domain entity', () {
      final model = LoginResponseModel.fromJson(tJson);
      final session = model.toAuthSession(nowMs: 1_000_000);

      expect(session, isA<AuthSession>());
      expect(session.accessToken, 'test_access_token');
      expect(session.tokenType, 'Bearer');
      expect(session.expiresIn, 3600);
      expect(session.refreshToken, 'test_refresh_token');
      expect(session.userVersion, 2);
      expect(session.accessExpiresAt, 1_000_000 + 3600 * 1000);
      expect(session.refreshExpiresAt, 1_000_000 + 7776000 * 1000);
      expect(session.user.id, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(session.user.email, 'user@example.com');
      expect(session.user.firstName, 'John');
      expect(session.user.lastName, 'Doe');
      expect(session.user.role, 'ADMIN');
      expect(session.user.schoolId, '8a9e5f7b-7f8f-4e39-9f89-c0744c5c9f20');
    });
  });
}
