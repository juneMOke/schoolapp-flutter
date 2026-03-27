import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class TokenStorageService {
  final FlutterSecureStorage _storage;

  const TokenStorageService(this._storage);

  Future<void> saveAuthSession(AuthSession session) async {
    await Future.wait(<Future<void>>[
      _storage.write(
        key: AppConstants.accessTokenKey,
        value: session.accessToken,
      ),
      _storage.write(
        key: AppConstants.tokenTypeKey,
        value: session.tokenType,
      ),
      _storage.write(
        key: AppConstants.expiresInKey,
        value: session.expiresIn.toString(),
      ),
      _storage.write(
        key: AppConstants.userIdKey,
        value: session.user.id,
      ),
      _storage.write(
        key: AppConstants.userEmailKey,
        value: session.user.email,
      ),
      _storage.write(
        key: AppConstants.userFirstNameKey,
        value: session.user.firstName,
      ),
      _storage.write(
        key: AppConstants.userLastNameKey,
        value: session.user.lastName,
      ),
      _storage.write(
        key: AppConstants.userRoleKey,
        value: session.user.role,
      ),
      _storage.write(
        key: AppConstants.userCreatedAtKey,
        value: session.user.createdAt,
      ),
    ]);
  }

  Future<AuthSession?> readAuthSession() async {
    final accessToken =
        await _storage.read(key: AppConstants.accessTokenKey);
    if (accessToken == null) return null;

    final tokenType =
        await _storage.read(key: AppConstants.tokenTypeKey) ?? 'Bearer';
    final expiresInStr =
        await _storage.read(key: AppConstants.expiresInKey) ?? '0';
    final userId = await _storage.read(key: AppConstants.userIdKey) ?? '';
    final userEmail =
        await _storage.read(key: AppConstants.userEmailKey) ?? '';
    final userFirstName =
        await _storage.read(key: AppConstants.userFirstNameKey) ?? '';
    final userLastName =
        await _storage.read(key: AppConstants.userLastNameKey) ?? '';
    final userRole =
        await _storage.read(key: AppConstants.userRoleKey) ?? '';
    final userCreatedAt =
        await _storage.read(key: AppConstants.userCreatedAtKey) ?? '';

    return AuthSession(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresIn: int.tryParse(expiresInStr) ?? 0,
      user: AuthenticatedUser(
        id: userId,
        email: userEmail,
        firstName: userFirstName,
        lastName: userLastName,
        role: userRole,
        createdAt: userCreatedAt,
      ),
    );
  }

  Future<void> clearAuthSession() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: AppConstants.tokenTypeKey),
      _storage.delete(key: AppConstants.expiresInKey),
      _storage.delete(key: AppConstants.userIdKey),
      _storage.delete(key: AppConstants.userEmailKey),
      _storage.delete(key: AppConstants.userFirstNameKey),
      _storage.delete(key: AppConstants.userLastNameKey),
      _storage.delete(key: AppConstants.userRoleKey),
      _storage.delete(key: AppConstants.userCreatedAtKey),
    ]);
  }
}
