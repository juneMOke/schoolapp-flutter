import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/check_auth_status_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/login_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/logout_use_case.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockCheckAuthStatusUseCase extends Mock implements CheckAuthStatusUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

const tUser = AuthenticatedUser(
  id: 'user-id',
  email: 'test@example.com',
  firstName: 'John',
  lastName: 'Doe',
  role: 'ADMIN',
  createdAt: '2026-01-01T00:00:00.000Z',
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

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockCheckAuthStatusUseCase = MockCheckAuthStatusUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
  });

  AuthBloc buildBloc() => AuthBloc(
        loginUseCase: mockLoginUseCase,
        checkAuthStatusUseCase: mockCheckAuthStatusUseCase,
        logoutUseCase: mockLogoutUseCase,
      );

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when session exists',
      setUp: () {
        when(() => mockCheckAuthStatusUseCase())
            .thenAnswer((_) async => const Right(tSession));
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
        when(() => mockCheckAuthStatusUseCase())
            .thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] on storage failure',
      setUp: () {
        when(() => mockCheckAuthStatusUseCase()).thenAnswer(
          (_) async => const Left(StorageFailure('Storage error')),
        );
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
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.authenticated, user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, failure] on invalid credentials',
      setUp: () {
        when(
          () => mockLoginUseCase(
            email: 'test@example.com',
            password: 'wrong',
          ),
        ).thenAnswer(
          (_) async =>
              const Left(InvalidCredentialsFailure('Invalid credentials')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@example.com',
          password: 'wrong',
        ),
      ),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Invalid credentials',
        ),
      ],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] on successful logout',
      setUp: () {
        when(() => mockLogoutUseCase())
            .thenAnswer((_) async => const Right(null));
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
        when(() => mockLogoutUseCase()).thenAnswer(
          (_) async => const Left(StorageFailure('Storage error')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Storage error',
        ),
      ],
    );
  });
}
