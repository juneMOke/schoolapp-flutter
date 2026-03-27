import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> getSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final TokenStorageService _tokenStorageService;

  const AuthLocalDataSourceImpl(this._tokenStorageService);

  @override
  Future<void> saveSession(AuthSession session) =>
      _tokenStorageService.saveAuthSession(session);

  @override
  Future<AuthSession?> getSession() =>
      _tokenStorageService.readAuthSession();

  @override
  Future<void> clearSession() => _tokenStorageService.clearAuthSession();
}
