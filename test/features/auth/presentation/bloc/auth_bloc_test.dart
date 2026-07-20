import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session_snapshot.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/check_auth_status_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/login_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/logout_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockCheckAuthStatusUseCase extends Mock
    implements CheckAuthStatusUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthSessionManager extends Mock implements AuthSessionManager {}

const tUser = AuthenticatedUser(
  email: 'test@example.com',
  firstName: 'John',
  lastName: 'Doe',
  role: 'ADMIN',
  schoolId: '8a9e5f7b-7f8f-4e39-9f89-c0744c5c9f20',
);

const tSession = AuthSession(
  accessToken: 'token123',
  tokenType: 'Bearer',
  expiresIn: 86400,
  user: tUser,
);

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockCheckAuthStatusUseCase mockCheckAuthStatusUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockResetPasswordUseCase mockResetPasswordUseCase;
  late MockAuthRepository mockRepository;
  late MockAuthSessionManager mockSessionManager;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockCheckAuthStatusUseCase = MockCheckAuthStatusUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockResetPasswordUseCase = MockResetPasswordUseCase();
    mockRepository = MockAuthRepository();
    mockSessionManager = MockAuthSessionManager();
    // Par défaut : aucune session locale à évaluer (mode NORMAL implicite).
    when(
      () => mockSessionManager.evaluateFreshness(),
    ).thenAnswer((_) async => null);
    when(() => mockSessionManager.wipeSession()).thenAnswer((_) async {});
    when(() => mockSessionManager.primeCurrentUser(any())).thenReturn(null);
  });

  AuthBloc buildBloc() => AuthBloc(
    loginUseCase: mockLoginUseCase,
    checkAuthStatusUseCase: mockCheckAuthStatusUseCase,
    logoutUseCase: mockLogoutUseCase,
    resetPasswordUseCase: mockResetPasswordUseCase,
    repository: mockRepository,
    sessionManager: mockSessionManager,
  );

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when session exists',
      setUp: () {
        when(
          () => mockCheckAuthStatusUseCase(),
        ).thenAnswer((_) async => const Right(tSession));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] when no session exists',
      setUp: () {
        when(
          () => mockCheckAuthStatusUseCase(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.unauthenticated),
      ],
      // Invariant « unauthenticated ⇒ zéro jeton vivant » (revue I3) : un
      // refresh actif résiduel doit être re-consigné, jamais laissé mintable
      // en arrière-plan pendant que l'écran de login est affiché.
      verify: (_) {
        verify(() => mockSessionManager.wipeSession()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] on storage failure',
      setUp: () {
        when(
          () => mockCheckAuthStatusUseCase(),
        ).thenAnswer((_) async => const Left(StorageFailure('Storage error')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Storage error',
        ),
      ],
    );
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] on successful login',
      setUp: () {
        when(
          () => mockLoginUseCase(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => const Right(tSession));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      // Le handler login applique un plancher d'affichage de 400 ms (spec §07).
      wait: const Duration(milliseconds: 450),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, failure] on invalid credentials',
      setUp: () {
        when(
          () => mockLoginUseCase(email: 'test@example.com', password: 'wrong'),
        ).thenAnswer(
          (_) async =>
              const Left(InvalidCredentialsFailure('Invalid credentials')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 'test@example.com', password: 'wrong'),
      ),
      wait: const Duration(milliseconds: 450),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Invalid credentials',
          errorKind: AuthErrorKind.invalidCredentials,
        ),
      ],
    );
  });

  group('AuthLoginRequested — repli offline (ADR-010)', () {
    const tNetworkFailure = NetworkFailure('Network error occurred');

    void stubOnlineLoginNetworkFailure() {
      when(
        () => mockLoginUseCase(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => const Left(tNetworkFailure));
    }

    blocTest<AuthBloc, AuthState>(
      'échec réseau + compte vu → authenticated offline (mode du snapshot)',
      setUp: () {
        stubOnlineLoginNetworkFailure();
        when(
          () => mockRepository.hasLocalUser('test@example.com'),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.loginOffline(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer(
          (_) async => const Right(
            AuthSessionSnapshot(
              session: tSession,
              mode: SessionMode.warning,
              isOffline: true,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      wait: const Duration(milliseconds: 450),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.authenticated,
          user: tUser,
          sessionMode: SessionMode.warning,
          isOffline: true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'échec réseau + compte jamais vu → offlineFirstLoginRequired (D-01)',
      setUp: () {
        stubOnlineLoginNetworkFailure();
        when(
          () => mockRepository.hasLocalUser('test@example.com'),
        ).thenAnswer((_) async => false);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      wait: const Duration(milliseconds: 450),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Network error occurred',
          errorKind: AuthErrorKind.offlineFirstLoginRequired,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'fenêtre offline close (AuthFailure) → offlineWindowExpired',
      setUp: () {
        stubOnlineLoginNetworkFailure();
        when(
          () => mockRepository.hasLocalUser('test@example.com'),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.loginOffline(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer(
          (_) async => const Left(
            AuthFailure('Reconnexion en ligne requise sur ce compte'),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      wait: const Duration(milliseconds: 450),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Reconnexion en ligne requise sur ce compte',
          errorKind: AuthErrorKind.offlineWindowExpired,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'mot de passe incorrect offline → invalidCredentials (même bandeau qu\'online)',
      setUp: () {
        stubOnlineLoginNetworkFailure();
        when(
          () => mockRepository.hasLocalUser('test@example.com'),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.loginOffline(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer(
          (_) async =>
              const Left(InvalidCredentialsFailure('Mot de passe incorrect')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      wait: const Duration(milliseconds: 450),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Mot de passe incorrect',
          errorKind: AuthErrorKind.invalidCredentials,
        ),
      ],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] on successful logout',
      setUp: () {
        when(
          () => mockLogoutUseCase(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, failure] when logout fails',
      setUp: () {
        when(
          () => mockLogoutUseCase(),
        ).thenAnswer((_) async => const Left(StorageFailure('Storage error')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.failure, errorMessage: 'Storage error'),
      ],
    );
  });
}
