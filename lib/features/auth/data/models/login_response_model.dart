import 'package:school_app_flutter/features/auth/data/jwt_claims.dart';
import 'package:school_app_flutter/features/auth/data/models/user_model.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';

/// Réponse de `/auth/login` et `/auth/refresh` (le refresh réutilise le même
/// record, ADR-010 §7.2). Contrat amendé §0.2 : `expiresIn`/`refreshExpiresIn`
/// relatifs en secondes, `userVersion` présent.
class LoginResponseModel {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;
  final int? refreshExpiresIn;
  final int userVersion;
  final UserModel user;

  const LoginResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshToken,
    required this.refreshExpiresIn,
    required this.userVersion,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Le refresh (§7.2) réutilise ce record mais **peut omettre `user`** (le
    // client l'ignore au refresh). On tolère donc son absence — sinon un cast
    // `null as Map` ferait échouer chaque refresh transparent. À la connexion,
    // le serveur fournit toujours `user`.
    final userJson = json['user'];
    return LoginResponseModel(
      accessToken: json['accessToken'] as String,
      tokenType: (json['tokenType'] ?? 'Bearer') as String,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      refreshToken: json['refreshToken'] as String?,
      refreshExpiresIn: (json['refreshExpiresIn'] as num?)?.toInt(),
      userVersion: (json['userVersion'] as num?)?.toInt() ?? 0,
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : const UserModel(
              email: '',
              firstName: '',
              lastName: '',
              role: '',
              schoolId: '',
            ),
    );
  }

  /// Construit la session applicative. [nowMs] (epoch ms) ancre les bornes
  /// absolues d'expiration. L'`uid` est pris du `user.id` s'il est fourni, sinon
  /// lu depuis le claim `uid` du JWT (les deux doivent coïncider, §0.2).
  AuthSession toAuthSession({required int nowMs}) {
    final claimUid = JwtClaims.uid(accessToken);
    final AuthenticatedUser resolvedUser = user.id.isNotEmpty
        ? user.toAuthenticatedUser()
        : AuthenticatedUser(
            id: claimUid ?? '',
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            role: user.role,
            schoolId: user.schoolId,
          );

    return AuthSession(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      refreshToken: refreshToken,
      refreshExpiresIn: refreshExpiresIn,
      accessExpiresAt: nowMs + expiresIn * 1000,
      refreshExpiresAt: refreshExpiresIn != null
          ? nowMs + refreshExpiresIn! * 1000
          : null,
      userVersion: userVersion,
      user: resolvedUser,
    );
  }
}
