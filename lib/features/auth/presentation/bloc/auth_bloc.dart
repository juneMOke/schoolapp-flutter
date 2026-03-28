import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/check_auth_status_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/login_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/logout_use_case.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
        _checkAuthStatusUseCase = checkAuthStatusUseCase,
        _logoutUseCase = logoutUseCase,
        super(AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    // Ajout d'un délai pour afficher la page splash
    await Future.delayed(const Duration(seconds: 2));

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
            ? AuthState(
                status: AuthStatus.authenticated,
                user: session.user,
              )
            : const AuthState(status: AuthStatus.unauthenticated),
      ),
    );
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (session) => emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
        ),
      ),
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _logoutUseCase();
    result.fold(
      (failure) => emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
    );
  }
}
