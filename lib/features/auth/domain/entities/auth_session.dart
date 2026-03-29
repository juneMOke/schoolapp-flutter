import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class AuthSession extends Equatable {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final AuthenticatedUser user;

  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  @override
  List<Object?> get props => [accessToken, tokenType, expiresIn, user];
}
