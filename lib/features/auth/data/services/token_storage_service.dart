import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

/// Persistance des **secrets** de session dans le secure storage (Keystore).
///
/// ADR-010 : le refresh token vit ici (jamais en base) — il doit survivre à un
/// wipe de session. L'access token et les bornes d'expiration l'accompagnent.
/// L'état durable non secret (mode dégradé, ancre serveur, `userVersion`) vit,
/// lui, dans `auth_local` (SQLCipher).
class TokenStorageService {
  final FlutterSecureStorage _storage;

  const TokenStorageService(this._storage);

  Future<void> saveAuthSession(AuthSession session) async {
    await Future.wait(<Future<void>>[
      _storage.write(
        key: AppConstants.accessTokenKey,
        value: session.accessToken,
      ),
      _storage.write(key: AppConstants.tokenTypeKey, value: session.tokenType),
      _storage.write(
        key: AppConstants.expiresInKey,
        value: session.expiresIn.toString(),
      ),
      _writeOrDelete(AppConstants.refreshTokenKey, session.refreshToken),
      _writeOrDelete(
        AppConstants.accessExpiresAtKey,
        session.accessExpiresAt?.toString(),
      ),
      _writeOrDelete(
        AppConstants.refreshExpiresAtKey,
        session.refreshExpiresAt?.toString(),
      ),
      _writeOrDelete(AppConstants.userIdKey, session.user.id),
      _storage.write(key: AppConstants.userEmailKey, value: session.user.email),
      _storage.write(
        key: AppConstants.userFirstNameKey,
        value: session.user.firstName,
      ),
      _storage.write(
        key: AppConstants.userLastNameKey,
        value: session.user.lastName,
      ),
      _storage.write(key: AppConstants.userRoleKey, value: session.user.role),
      _storage.write(
        key: AppConstants.userSchoolIdKey,
        value: session.user.schoolId,
      ),
    ]);
  }

  /// Réécrit **uniquement** les jetons + bornes après un refresh (§7.2), sans
  /// toucher le profil utilisateur déjà stocké.
  ///
  /// Le refresh token n'est réécrit que s'il est **fourni** : un backend à
  /// refresh **non rotatif** ne renvoie qu'un nouvel access token → on préserve
  /// le refresh token existant plutôt que de l'effacer (sinon le refresh suivant
  /// serait impossible). Idem pour la borne d'expiration du refresh.
  Future<void> updateTokens(AuthSession session) async {
    await Future.wait(<Future<void>>[
      _storage.write(
        key: AppConstants.accessTokenKey,
        value: session.accessToken,
      ),
      _storage.write(key: AppConstants.tokenTypeKey, value: session.tokenType),
      _storage.write(
        key: AppConstants.expiresInKey,
        value: session.expiresIn.toString(),
      ),
      _writeIfPresent(AppConstants.refreshTokenKey, session.refreshToken),
      _writeIfPresent(
        AppConstants.accessExpiresAtKey,
        session.accessExpiresAt?.toString(),
      ),
      _writeIfPresent(
        AppConstants.refreshExpiresAtKey,
        session.refreshExpiresAt?.toString(),
      ),
    ]);
  }

  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  Future<AuthSession?> readAuthSession() async {
    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    if (accessToken == null) return null;

    final tokenType =
        await _storage.read(key: AppConstants.tokenTypeKey) ?? 'Bearer';
    final expiresInStr =
        await _storage.read(key: AppConstants.expiresInKey) ?? '0';
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    final accessExpiresAt = await _storage.read(
      key: AppConstants.accessExpiresAtKey,
    );
    final refreshExpiresAt = await _storage.read(
      key: AppConstants.refreshExpiresAtKey,
    );
    final userId = await _storage.read(key: AppConstants.userIdKey) ?? '';
    final userEmail = await _storage.read(key: AppConstants.userEmailKey) ?? '';
    final userFirstName =
        await _storage.read(key: AppConstants.userFirstNameKey) ?? '';
    final userLastName =
        await _storage.read(key: AppConstants.userLastNameKey) ?? '';
    final userRole = await _storage.read(key: AppConstants.userRoleKey) ?? '';
    final userSchoolId =
        await _storage.read(key: AppConstants.userSchoolIdKey) ?? '';

    return AuthSession(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresIn: int.tryParse(expiresInStr) ?? 0,
      refreshToken: refreshToken,
      accessExpiresAt: int.tryParse(accessExpiresAt ?? ''),
      refreshExpiresAt: int.tryParse(refreshExpiresAt ?? ''),
      user: AuthenticatedUser(
        id: userId,
        email: userEmail,
        firstName: userFirstName,
        lastName: userLastName,
        role: userRole,
        schoolId: userSchoolId,
      ),
    );
  }

  Future<void> clearAuthSession() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: AppConstants.tokenTypeKey),
      _storage.delete(key: AppConstants.expiresInKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
      _storage.delete(key: AppConstants.accessExpiresAtKey),
      _storage.delete(key: AppConstants.refreshExpiresAtKey),
      _storage.delete(key: AppConstants.userIdKey),
      _storage.delete(key: AppConstants.userEmailKey),
      _storage.delete(key: AppConstants.userFirstNameKey),
      _storage.delete(key: AppConstants.userLastNameKey),
      _storage.delete(key: AppConstants.userRoleKey),
      _storage.delete(key: AppConstants.userSchoolIdKey),
    ]);
  }

  Future<void> _writeOrDelete(String key, String? value) {
    if (value == null || value.isEmpty) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
  }

  /// Écrit la valeur si fournie ; **ne supprime pas** si absente (préserve
  /// l'existant — refresh non rotatif).
  Future<void> _writeIfPresent(String key, String? value) {
    if (value == null || value.isEmpty) return Future<void>.value();
    return _storage.write(key: key, value: value);
  }
}
