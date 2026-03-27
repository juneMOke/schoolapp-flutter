import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

// Sentinel object used to distinguish "not provided" from explicit null in copyWith.
const _undefined = Object();

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthenticatedUser? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
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
  }) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _undefined)
          ? this.user
          : user as AuthenticatedUser?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
