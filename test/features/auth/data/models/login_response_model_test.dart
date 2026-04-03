import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/data/models/login_response_model.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';

void main() {
  group('LoginResponseModel', () {
    const tJson = <String, dynamic>{
      'accessToken': 'test_access_token',
      'tokenType': 'Bearer',
      'expiresIn': 86400,
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
      expect(model.expiresIn, 86400);
      expect(model.user.email, 'user@example.com');
      expect(model.user.firstName, 'John');
      expect(model.user.lastName, 'Doe');
      expect(model.user.role, 'ADMIN');
      expect(model.user.schoolId, '8a9e5f7b-7f8f-4e39-9f89-c0744c5c9f20');
    });

    test('toAuthSession converts model to domain entity', () {
      final model = LoginResponseModel.fromJson(tJson);
      final session = model.toAuthSession();

      expect(session, isA<AuthSession>());
      expect(session.accessToken, 'test_access_token');
      expect(session.tokenType, 'Bearer');
      expect(session.expiresIn, 86400);
      expect(session.user.email, 'user@example.com');
      expect(session.user.firstName, 'John');
      expect(session.user.lastName, 'Doe');
      expect(session.user.role, 'ADMIN');
      expect(session.user.schoolId, '8a9e5f7b-7f8f-4e39-9f89-c0744c5c9f20');
    });
  });
}
