import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

/// Catégorie d'échec de connexion — pilote la tonalité et l'action du bandeau
/// d'erreur (spec Connexion §08). Découple l'UI du texte brut de la [Failure].
///
/// [accountDisabled] (403) et [rateLimited] (429) ne sont pas encore émis : le
/// backend n'expose pas les signaux correspondants. Le bandeau les gère déjà —
/// il suffira de les mapper dans [AuthBloc] quand le contrat sera disponible.
enum AuthErrorKind {
  invalidCredentials,
  network,
  accountDisabled,
  rateLimited,
  server,
  generic,

  /// Hors ligne ET compte jamais vu online sur ce device (ADR-010 D-01) : le
  /// login offline est impossible — une première connexion en ligne est requise.
  offlineFirstLoginRequired,

  /// Hors ligne ET fenêtre de travail offline close (borne refresh dépassée ou
  /// brûlée par une révocation) : reconnexion en ligne exigée (ADR-010 D-07/D-09).
  offlineWindowExpired,
}

// Sentinel object used to distinguish "not provided" from explicit null in copyWith.
const _undefined = Object();

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthenticatedUser? user;
  final String? errorMessage;
  final AuthErrorKind? errorKind;

  /// Axe **orthogonal** au statut (ADR-010 §6) : la dégradation de la session
  /// offline. Ne vaut que quand [status] == [AuthStatus.authenticated].
  /// READ_ONLY **reste** authenticated (le router ne bascule pas) — seule une
  /// révocation / expiration du refresh renvoie à `unauthenticated`.
  final SessionMode sessionMode;

  /// Vrai si la session courante a été ouverte **hors ligne** (vérificateur
  /// local, sans contact serveur). Diagnostic UX (bandeau).
  final bool isOffline;

  /// Permissions effectives de la session (ADR-014 §4). **Projection
  /// d'affichage, jamais une autorité** : le serveur re-dérive l'autorisation à
  /// chaque requête — masquer un module ici n'en interdit pas l'accès, et le
  /// laisser visible ne l'autorise pas. Ensemble OUVERT : toute valeur inconnue
  /// de cette version de l'application est ignorée en silence.
  ///
  /// **Trois états.** `null` = ensemble inconnu — session ouverte avant que
  /// l'application ne sache lire les permissions, ou réponse serveur sans le
  /// champ ; liste vide = aucun droit, ce que le serveur a dit ; liste peuplée
  /// = droits connus. Les deux premiers ferment l'interface mais ne disent pas
  /// la même chose à l'utilisateur : « reconnectez-vous » n'est pas
  /// « contactez l'administrateur ».
  ///
  /// L'ensemble ne descend qu'au login et au refresh ; il est réévalué au tick
  /// de fraîcheur.
  final List<String>? permissions;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.errorKind,
    this.sessionMode = SessionMode.normal,
    this.isOffline = false,
    this.permissions,
  });

  /// Vrai si la session porte [permission]. Unique point de lecture : les
  /// appelants ne doivent pas refaire le `contains` eux-mêmes, sous peine de
  /// diverger le jour où l'ensemble gagnera une hiérarchie (`a.*`).
  bool hasPermission(String permission) =>
      permissions?.contains(permission) ?? false;

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  /// Returns a copy of this state with the given fields replaced.
  ///
  /// Pass [clearUser] or [clearErrorMessage] as `true` to explicitly set
  /// the corresponding nullable field to `null`.
  AuthState copyWith({
    AuthStatus? status,
    Object? user = _undefined,
    Object? errorMessage = _undefined,
    Object? errorKind = _undefined,
    SessionMode? sessionMode,
    bool? isOffline,
    Object? permissions = _undefined,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _undefined)
          ? this.user
          : user as AuthenticatedUser?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
      errorKind: identical(errorKind, _undefined)
          ? this.errorKind
          : errorKind as AuthErrorKind?,
      sessionMode: sessionMode ?? this.sessionMode,
      isOffline: isOffline ?? this.isOffline,
      permissions: identical(permissions, _undefined)
          ? this.permissions
          : permissions as List<String>?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    errorMessage,
    errorKind,
    sessionMode,
    isOffline,
    permissions,
  ];
}
