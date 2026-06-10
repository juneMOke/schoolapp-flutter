import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/check_auth_status_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/login_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/logout_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final LogoutUseCase _logoutUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required LogoutUseCase logoutUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  }) : _loginUseCase = loginUseCase,
       _checkAuthStatusUseCase = checkAuthStatusUseCase,
       _logoutUseCase = logoutUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       super(AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _checkAuthStatusUseCase();
    result.fold(
      (failure) => emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        ),
      ),
      (session) => emit(
        session != null
            ? AuthState(status: AuthStatus.authenticated, user: session.user)
            : const AuthState(status: AuthStatus.unauthenticated),
      ),
    );
  }

  /// Plancher d'affichage du spinner de connexion (spec Connexion §07) : évite
  /// un flash si l'API répond instantanément.
  static const _minSubmitDelay = Duration(milliseconds: 400);

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    // On lance la requête puis on attend le plancher : la durée totale vaut
    // max(durée réelle, 400 ms) sans jamais retarder une réponse lente.
    final loginFuture = _loginUseCase(
      email: event.email,
      password: event.password,
    );
    await Future<void>.delayed(_minSubmitDelay);
    final result = await loginFuture;
    result.fold(
      (failure) => emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: failure.message,
          errorKind: _mapFailureToKind(failure),
        ),
      ),
      (session) =>
          emit(AuthState(status: AuthStatus.authenticated, user: session.user)),
    );
  }

  /// Classe la [Failure] de login pour la tonalité du bandeau (spec §08).
  /// 403 (compte désactivé) et 429 (verrouillage) ne sont pas distingués tant
  /// que le backend n'expose pas ces signaux → repli sur [AuthErrorKind.generic].
  AuthErrorKind _mapFailureToKind(Failure failure) {
    if (failure is InvalidCredentialsFailure) {
      return AuthErrorKind.invalidCredentials;
    }
    if (failure is NetworkFailure) return AuthErrorKind.network;
    if (failure is ServerFailure) return AuthErrorKind.server;
    return AuthErrorKind.generic;
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _logoutUseCase();
    result.fold(
      (failure) => emit(
        AuthState(status: AuthStatus.failure, errorMessage: failure.message),
      ),
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
    );
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _resetPasswordUseCase(
      email: event.email,
      newPassword: event.newPassword,
      otpToken: event.otpToken,
    );

    result.fold(
      (failure) => emit(
        AuthState(status: AuthStatus.failure, errorMessage: failure.message),
      ),
      (_) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
    );
  }
}
