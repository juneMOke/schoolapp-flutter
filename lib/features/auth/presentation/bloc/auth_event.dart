import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Tick périodique (timer) : recalcule le mode de dégradation sans réseau
/// (ADR-010 D-08). Le temps ne peut que dégrader.
class AuthFreshnessTick extends AuthEvent {
  const AuthFreshnessTick();
}

/// Le serveur a révoqué la session (`userVersion` divergent, D-09) : wipe de la
/// **session** (jamais l'outbox) et retour à `unauthenticated`.
class AuthSessionRevoked extends AuthEvent {
  const AuthSessionRevoked();
}

/// Le refresh token est expiré/rejeté (D-07/§7.2) : reconnexion interactive
/// obligatoire.
class AuthRefreshExpired extends AuthEvent {
  const AuthRefreshExpired();
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;
  final String newPassword;
  final String otpToken;

  const AuthResetPasswordRequested({
    required this.email,
    required this.newPassword,
    required this.otpToken,
  });

  @override
  List<Object?> get props => [email, newPassword, otpToken];
}
