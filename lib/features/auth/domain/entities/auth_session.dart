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
/// Sentinelle du `copyWith` : distingue « ne touche pas au champ » de « pose
/// `null` », qui est une valeur significative depuis le tri-état.
const Object _unset = Object();

class AuthSession extends Equatable {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;
  final int? refreshExpiresIn;
  final int? accessExpiresAt;
  final int? refreshExpiresAt;
  final int userVersion;

  /// Permissions effectives portées par la session (ADR-014 §4). Elles ne
  /// voyagent que sur login/refresh, jamais sur les pages de sync : un
  /// [userVersion] qui bouge signale qu'il faut rafraîchir pour récupérer le
  /// nouvel ensemble.
  ///
  /// Liste vide = aucun droit ; `null` = ensemble **inconnu** (session d'avant
  /// ADR-014, ou réponse serveur sans le champ). Les deux ferment l'interface,
  /// mais ne disent pas la même chose à l'utilisateur et n'ont pas le même
  /// effet sur la synchronisation.
  final List<String>? permissions;

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
    this.permissions,
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
    Object? permissions = _unset,
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
      // `??` confondrait « pose null » et « ne touche pas » — et son unique
      // appelant, le login offline, affirme l'invariant inverse : les droits
      // d'une session hors ligne viennent de la copie durable, jamais du
      // secure storage.
      permissions: identical(permissions, _unset)
          ? this.permissions
          : permissions as List<String>?,
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
    permissions,
    user,
  ];
}
