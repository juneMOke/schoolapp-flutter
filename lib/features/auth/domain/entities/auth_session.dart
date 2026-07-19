import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

/// Transport de session applicative (ADR-010 D-07 : trois horloges).
///
/// [expiresIn] / [refreshExpiresIn] sont des TTL **relatifs en secondes** (contrat
/// amendé §0.2 décision 3). [accessExpiresAt] / [refreshExpiresAt] sont les
/// bornes **absolues** (epoch ms) calculées à la connexion, servant au calcul de
/// refresh et de dégradation. [userVersion] n'est significatif qu'à la sortie du
/// serveur (login/refresh) ; la valeur **canonique** de révocation vit dans
/// `auth_local_user` (comparée par le guardian).
class AuthSession extends Equatable {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;
  final int? refreshExpiresIn;
  final int? accessExpiresAt;
  final int? refreshExpiresAt;
  final int userVersion;
  final AuthenticatedUser user;

  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
    this.refreshExpiresIn,
    this.accessExpiresAt,
    this.refreshExpiresAt,
    this.userVersion = 0,
    required this.user,
  });

  AuthSession copyWith({
    String? accessToken,
    String? tokenType,
    int? expiresIn,
    String? refreshToken,
    int? refreshExpiresIn,
    int? accessExpiresAt,
    int? refreshExpiresAt,
    int? userVersion,
    AuthenticatedUser? user,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      refreshToken: refreshToken ?? this.refreshToken,
      refreshExpiresIn: refreshExpiresIn ?? this.refreshExpiresIn,
      accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
      userVersion: userVersion ?? this.userVersion,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
    accessToken,
    tokenType,
    expiresIn,
    refreshToken,
    refreshExpiresIn,
    accessExpiresAt,
    refreshExpiresAt,
    userVersion,
    user,
  ];
}
