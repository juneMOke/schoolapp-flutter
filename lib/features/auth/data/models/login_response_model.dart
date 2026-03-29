import 'package:school_app_flutter/features/auth/data/models/user_model.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';

class LoginResponseModel {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  const LoginResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        accessToken: json['accessToken'] as String,
        tokenType: json['tokenType'] as String,
        expiresIn: json['expiresIn'] as int,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );

  AuthSession toAuthSession() => AuthSession(
        accessToken: accessToken,
        tokenType: tokenType,
        expiresIn: expiresIn,
        user: user.toAuthenticatedUser(),
      );
}
