import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

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
}

// Sentinel object used to distinguish "not provided" from explicit null in copyWith.
const _undefined = Object();

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthenticatedUser? user;
  final String? errorMessage;
  final AuthErrorKind? errorKind;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.errorKind,
  });

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
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, errorKind];
}
