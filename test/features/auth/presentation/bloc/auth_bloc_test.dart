import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session_snapshot.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';
import 'package:school_app_flutter/features/auth/domain/session_freshness.dart';
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
    // Par défaut : aucune copie durable — l'état reste « jamais renseigné »
    // quand la réponse ne communique pas d'ensemble.
    when(
      () => mockSessionManager.currentPermissions(),
    ).thenAnswer((_) async => null);
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

  // ── Permissions (ADR-014 §4) ──────────────────────────────────────────────
  // L'état les EXPOSE, il ne les arbitre pas : le serveur reste l'autorité.
  group('permissions', () {
    const tPermissions = <String>['attendance.read', 'classroom.read'];
    const tSessionWithPermissions = AuthSession(
      accessToken: 'token123',
      tokenType: 'Bearer',
      expiresIn: 86400,
      permissions: tPermissions,
      user: tUser,
    );

    // « Absent » n'est pas « vide » — règle que toutes les couches de
    // persistance appliquent déjà (`recordOnlineLogin` fusionne avec
    // l'existant, `updatePermissions` et `updateTokens` ne font rien sur
    // `null`). Sans elle dans le bloc, une réponse qui omet le champ vidait la
    // grille de modules et faisait rediriger la coquille vers l'accueil,
    // jusqu'au tick de fraîcheur — cinq minutes plus tard.
    blocTest<AuthBloc, AuthState>(
      'login sans ensemble communiqué : la copie durable tient l\'état',
      setUp: () {
        when(
          () => mockLoginUseCase(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => const Right(tSession));
        when(
          () => mockSessionManager.currentPermissions(),
        ).thenAnswer((_) async => tPermissions);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      wait: const Duration(milliseconds: 500),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.authenticated,
          user: tUser,
          permissions: tPermissions,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'cold start sans ensemble en storage : la copie durable tient l\'état',
      setUp: () {
        when(
          () => mockCheckAuthStatusUseCase(),
        ).thenAnswer((_) async => const Right(tSession));
        when(
          () => mockSessionManager.currentPermissions(),
        ).thenAnswer((_) async => tPermissions);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.authenticated,
          user: tUser,
          permissions: tPermissions,
        ),
      ],
    );

    // Le pendant : un ensemble VIDE communiqué est un retrait de droits, il
    // écrase la copie durable au lieu de la laisser reprendre la main.
    blocTest<AuthBloc, AuthState>(
      'login avec un ensemble VIDE : le retrait prime sur la copie durable',
      setUp: () {
        when(
          () => mockLoginUseCase(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer(
          (_) async => const Right(
            AuthSession(
              accessToken: 'token123',
              tokenType: 'Bearer',
              expiresIn: 86400,
              permissions: <String>[],
              user: tUser,
            ),
          ),
        );
        when(
          () => mockSessionManager.currentPermissions(),
        ).thenAnswer((_) async => tPermissions);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      wait: const Duration(milliseconds: 500),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.authenticated,
          user: tUser,
          permissions: <String>[],
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'login online : l\'ensemble du serveur atterrit dans l\'état',
      setUp: () {
        when(
          () => mockLoginUseCase(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => const Right(tSessionWithPermissions));
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
          permissions: tPermissions,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'cold start : la session restaurée porte ses permissions',
      setUp: () {
        when(
          () => mockCheckAuthStatusUseCase(),
        ).thenAnswer((_) async => const Right(tSessionWithPermissions));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.authenticated,
          user: tUser,
          permissions: tPermissions,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'login offline : les droits de la copie durable sont exposés',
      setUp: () {
        when(
          () => mockLoginUseCase(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer(
          (_) async => const Left(NetworkFailure('Network error occurred')),
        );
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
              session: tSessionWithPermissions,
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
          permissions: tPermissions,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'logout : l\'état repart sans aucun droit',
      setUp: () {
        when(
          () => mockLogoutUseCase(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
        permissions: tPermissions,
      ),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => const [
        AuthState(
          status: AuthStatus.loading,
          user: tUser,
          permissions: tPermissions,
        ),
        AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    // Le refresh redescend les droits en arrière-plan, sans passer par le bloc :
    // sans relecture au tick, un retrait n'atteindrait l'écran qu'au prochain
    // démarrage.
    blocTest<AuthBloc, AuthState>(
      'tick de fraîcheur : un RETRAIT de droits atteint l\'état',
      setUp: () {
        when(() => mockSessionManager.evaluateFreshness()).thenAnswer(
          (_) async => const SessionEvaluation(
            refreshExpired: false,
            mode: SessionMode.normal,
          ),
        );
        when(
          () => mockSessionManager.currentPermissions(),
        ).thenAnswer((_) async => const ['attendance.read']);
      },
      build: buildBloc,
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
        permissions: tPermissions,
      ),
      act: (bloc) => bloc.add(const AuthFreshnessTick()),
      expect: () => const [
        AuthState(
          status: AuthStatus.authenticated,
          user: tUser,
          permissions: ['attendance.read'],
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'tick de fraîcheur : ensemble inchangé → aucune émission',
      setUp: () {
        when(() => mockSessionManager.evaluateFreshness()).thenAnswer(
          (_) async => const SessionEvaluation(
            refreshExpired: false,
            mode: SessionMode.normal,
          ),
        );
        when(
          () => mockSessionManager.currentPermissions(),
        ).thenAnswer((_) async => tPermissions);
      },
      build: buildBloc,
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
        permissions: tPermissions,
      ),
      act: (bloc) => bloc.add(const AuthFreshnessTick()),
      expect: () => const <AuthState>[],
    );

    // `null` = pas de session locale à interroger (session héritée sans uid) :
    // rien à dire ≠ retrait de droits. L'état garde ce qu'il a.
    blocTest<AuthBloc, AuthState>(
      'tick de fraîcheur : pas de session locale → droits conservés',
      setUp: () {
        when(() => mockSessionManager.evaluateFreshness()).thenAnswer(
          (_) async => const SessionEvaluation(
            refreshExpired: false,
            mode: SessionMode.normal,
          ),
        );
        when(
          () => mockSessionManager.currentPermissions(),
        ).thenAnswer((_) async => null);
      },
      build: buildBloc,
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
        permissions: tPermissions,
      ),
      act: (bloc) => bloc.add(const AuthFreshnessTick()),
      expect: () => const [
        AuthState(
          status: AuthStatus.authenticated,
          user: tUser,
          permissions: null,
        ),
      ],
    );

    test('hasPermission lit l\'ensemble exposé, fail-closed par défaut', () {
      const granted = AuthState(
        status: AuthStatus.authenticated,
        user: tUser,
        permissions: tPermissions,
      );
      expect(granted.hasPermission('attendance.read'), isTrue);
      expect(granted.hasPermission('finance.write'), isFalse);

      // Hors session, l'ensemble est inconnu (`null`) : aucun droit accordé.
      expect(
        const AuthState(
          status: AuthStatus.unauthenticated,
        ).hasPermission('attendance.read'),
        isFalse,
      );
    });
  });
}
