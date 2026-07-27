import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';
import 'package:school_app_flutter/features/auth/domain/session_revocation_bus.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/check_auth_status_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/login_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/logout_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final LogoutUseCase _logoutUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final AuthRepository _repository;
  final AuthSessionManager _sessionManager;
  final SessionRevocationBus? _revocationBus;

  /// Recalcul périodique de la dégradation (ADR-010 D-08). Sans réseau.
  Timer? _freshnessTimer;

  /// Abonnement au bus de révocation (D-09) : le guardian (boucle de synchro)
  /// wipe la session et publie → on repasse `unauthenticated`.
  StreamSubscription<void>? _revocationSub;

  /// Cadence du recalcul de fraîcheur (le mode évolue lentement, à l'échelle
  /// des jours — un tick fréquent est inutile).
  static const Duration _freshnessInterval = Duration(minutes: 5);

  AuthBloc({
    required LoginUseCase loginUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required LogoutUseCase logoutUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required AuthRepository repository,
    required AuthSessionManager sessionManager,
    SessionRevocationBus? revocationBus,
  }) : _loginUseCase = loginUseCase,
       _checkAuthStatusUseCase = checkAuthStatusUseCase,
       _logoutUseCase = logoutUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
       _repository = repository,
       _sessionManager = sessionManager,
       _revocationBus = revocationBus,
       super(AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
    on<AuthFreshnessTick>(_onFreshnessTick);
    on<AuthSessionRevoked>(_onSessionRevoked);
    on<AuthRefreshExpired>(_onRefreshExpired);
    _revocationSub = _revocationBus?.stream.listen(
      (_) => add(const AuthSessionRevoked()),
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _checkAuthStatusUseCase();
    await result.fold(
      (failure) async => emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        ),
      ),
      (session) async {
        if (session == null) {
          // Invariant « unauthenticated ⇒ zéro jeton vivant » (revue I3) : un
          // refresh ACTIF résiduel (session offline tuée par un restart —
          // access vide → session nulle ici) serait sinon minté en arrière-
          // plan par la boucle de synchro pendant que l'écran de login est
          // affiché, puis rouvrirait la session SANS mot de passe au prochain
          // démarrage. Le wipe ordinaire re-consigne ce refresh sous son uid :
          // la resync silencieuse reste disponible au prochain login offline.
          try {
            await _sessionManager.wipeSession();
          } catch (_) {
            // Best-effort : storage indisponible → la sonde de crédentiels
            // (défensive) bloquera de toute façon la boucle.
          }
          emit(const AuthState(status: AuthStatus.unauthenticated));
          return;
        }
        // Amorce l'uid depuis le token store AVANT tout accès aux écrans
        // d'écriture (ADR-010 D-05) : couvre le cold-start où `auth_local` n'a
        // pas de ligne de session (montée de version) — `evaluateFreshness` le
        // confirmera depuis `auth_local` s'il existe. Sans ça, une écriture
        // offline partirait avec `authorId` null → 403 terminal (cash bloqué).
        _sessionManager.primeCurrentUser(
          session.user.id,
          schoolId: session.user.schoolId,
        );
        // Session valide en storage : dériver le mode de dégradation courant.
        final eval = await _sessionManager.evaluateFreshness();
        if (eval != null && eval.refreshExpired) {
          await _sessionManager.wipeSession();
          emit(const AuthState(status: AuthStatus.unauthenticated));
          return;
        }
        emit(
          AuthState(
            status: AuthStatus.authenticated,
            user: session.user,
            sessionMode: eval?.mode ?? SessionMode.normal,
          ),
        );
        _startFreshnessTimer();
      },
    );
  }

  /// Plancher d'affichage du spinner de connexion (spec Connexion §07).
  static const _minSubmitDelay = Duration(milliseconds: 400);

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final loginFuture = _loginUseCase(
      email: event.email,
      password: event.password,
    );
    await Future<void>.delayed(_minSubmitDelay);
    final result = await loginFuture;

    await result.fold(
      (failure) => _handleOnlineLoginFailure(event, failure, emit),
      (session) async {
        emit(AuthState(status: AuthStatus.authenticated, user: session.user));
        _startFreshnessTimer();
      },
    );
  }

  /// Repli offline (ADR-010 D-01/D-02) : si le login online échoue faute de
  /// réseau **et** que l'utilisateur a déjà été vu online sur ce device, on
  /// tente une vérification locale du mot de passe.
  Future<void> _handleOnlineLoginFailure(
    AuthLoginRequested event,
    Failure failure,
    Emitter<AuthState> emit,
  ) async {
    if (failure is! NetworkFailure) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: failure.message,
          errorKind: _mapFailureToKind(failure),
        ),
      );
      return;
    }

    final seen = await _repository.hasLocalUser(event.email);
    if (!seen) {
      // Jamais connecté online ici → le login offline est impossible (D-01).
      // Le bandeau doit l'expliquer (≠ simple panne réseau) : sinon l'agent
      // retente en boucle un login qui ne peut pas aboutir sans réseau.
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: failure.message,
          errorKind: AuthErrorKind.offlineFirstLoginRequired,
        ),
      );
      return;
    }

    final offline = await _repository.loginOffline(
      email: event.email,
      password: event.password,
    );
    offline.fold(
      (offFailure) => emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: offFailure.message,
          errorKind: _mapOfflineFailureToKind(offFailure),
        ),
      ),
      (snapshot) {
        emit(
          AuthState(
            status: AuthStatus.authenticated,
            user: snapshot.session.user,
            sessionMode: snapshot.mode,
            isOffline: true,
          ),
        );
        _startFreshnessTimer();
      },
    );
  }

  AuthErrorKind _mapFailureToKind(Failure failure) {
    if (failure is InvalidCredentialsFailure) {
      return AuthErrorKind.invalidCredentials;
    }
    if (failure is NetworkFailure) return AuthErrorKind.network;
    if (failure is ServerFailure) return AuthErrorKind.server;
    return AuthErrorKind.generic;
  }

  /// Mapping des refus du **login offline** (`AuthSessionManager.loginOffline`) :
  /// un `AuthFailure` sur ce chemin signifie fenêtre offline close (borne
  /// dépassée, ou brûlée par une révocation D-09) → reconnexion online exigée.
  /// Le mot de passe incorrect reste `invalidCredentials` (même bandeau
  /// qu'online — l'agent n'a pas à savoir qui a vérifié).
  AuthErrorKind _mapOfflineFailureToKind(Failure failure) {
    if (failure is AuthFailure) return AuthErrorKind.offlineWindowExpired;
    return _mapFailureToKind(failure);
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
      (_) {
        _stopFreshnessTimer();
        emit(const AuthState(status: AuthStatus.unauthenticated));
      },
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
      (_) {
        // Cohérent avec les autres sorties de session (logout/revoked) : clear
        // du user + arrêt du timer de fraîcheur (piège #1 CLAUDE.md auth).
        _stopFreshnessTimer();
        emit(const AuthState(status: AuthStatus.unauthenticated));
      },
    );
  }

  // ── Session offline : fraîcheur / révocation / horloge (ADR-010) ─────────────

  Future<void> _onFreshnessTick(
    AuthFreshnessTick event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated) return;
    final eval = await _sessionManager.evaluateFreshness();
    if (eval == null) return;
    if (eval.refreshExpired) {
      add(const AuthRefreshExpired());
      return;
    }
    // Une session ouverte OFFLINE qui a eu un contact serveur réel depuis
    // (resynchronisation silencieuse post-déconsignation, V1.1) n'est plus
    // « hors ligne » : le bandeau tombe. Seul un contact réel l'éteint (D-08).
    final clearOffline = state.isOffline && eval.hadServerContact;
    if (eval.mode != state.sessionMode || clearOffline) {
      emit(
        state.copyWith(
          sessionMode: eval.mode,
          isOffline: clearOffline ? false : null,
        ),
      );
    }
  }

  Future<void> _onSessionRevoked(
    AuthSessionRevoked event,
    Emitter<AuthState> emit,
  ) async {
    _stopFreshnessTimer();
    // La session a déjà été wipée par le guardian (après flush, D-11).
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onRefreshExpired(
    AuthRefreshExpired event,
    Emitter<AuthState> emit,
  ) async {
    _stopFreshnessTimer();
    await _sessionManager.wipeSession();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _startFreshnessTimer() {
    _freshnessTimer?.cancel();
    _freshnessTimer = Timer.periodic(
      _freshnessInterval,
      (_) => add(const AuthFreshnessTick()),
    );
  }

  void _stopFreshnessTimer() {
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
  }

  @override
  Future<void> close() {
    _stopFreshnessTimer();
    _revocationSub?.cancel();
    return super.close();
  }
}
