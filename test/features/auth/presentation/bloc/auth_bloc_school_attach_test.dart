import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/check_auth_status_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/login_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/logout_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';

class _MockLogin extends Mock implements LoginUseCase {}

class _MockCheck extends Mock implements CheckAuthStatusUseCase {}

class _MockLogout extends Mock implements LogoutUseCase {}

class _MockReset extends Mock implements ResetPasswordUseCase {}

class _MockRepository extends Mock implements AuthRepository {}

class _MockSessionManager extends Mock implements AuthSessionManager {}

const _user = AuthenticatedUser(
  id: 'uid-a',
  email: 'direction@ecole-a.cd',
  firstName: 'Amina',
  lastName: 'Kalala',
  role: 'DIRECTOR',
  schoolId: 'school-a',
);

const _session = AuthSession(
  accessToken: 'token',
  tokenType: 'Bearer',
  expiresIn: 86400,
  user: _user,
);

/// Au démarrage, l'école de la session restaurée s'attache avant tout accès
/// aux écrans (MULTI_ECOLE_PLAN.md §10.2).
void main() {
  late _MockCheck check;
  late _MockSessionManager sessionManager;

  setUp(() {
    check = _MockCheck();
    sessionManager = _MockSessionManager();
    when(() => check()).thenAnswer((_) async => const Right(_session));
    when(
      () => sessionManager.evaluateFreshness(),
    ).thenAnswer((_) async => null);
    when(() => sessionManager.wipeSession()).thenAnswer((_) async {});
    when(
      () => sessionManager.primeCurrentUser(
        any(),
        schoolId: any(named: 'schoolId'),
        permissions: any(named: 'permissions'),
      ),
    ).thenReturn(null);
    when(
      () => sessionManager.currentPermissions(),
    ).thenAnswer((_) async => null);
  });

  AuthBloc build() => AuthBloc(
    loginUseCase: _MockLogin(),
    checkAuthStatusUseCase: check,
    logoutUseCase: _MockLogout(),
    resetPasswordUseCase: _MockReset(),
    repository: _MockRepository(),
    sessionManager: sessionManager,
  );

  blocTest<AuthBloc, AuthState>(
    'l école s attache AVANT que le contexte soit amorcé',
    setUp: () =>
        when(() => sessionManager.attachSchool(any())).thenAnswer((_) async {}),
    build: build,
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(status: AuthStatus.authenticated, user: _user),
    ],
    verify: (_) => verifyInOrder([
      () => sessionManager.attachSchool('school-a'),
      () => sessionManager.primeCurrentUser(
        'uid-a',
        schoolId: 'school-a',
        permissions: any(named: 'permissions'),
      ),
    ]),
  );

  blocTest<AuthBloc, AuthState>(
    'la base de l école ne s ouvre pas : retour à la connexion, jetons '
    'effacés, aucun contexte amorcé',
    setUp: () => when(
      () => sessionManager.attachSchool(any()),
    ).thenThrow(StateError('fichier illisible')),
    build: build,
    act: (bloc) => bloc.add(const AuthCheckRequested()),
    expect: () => const [
      AuthState(status: AuthStatus.loading),
      AuthState(status: AuthStatus.unauthenticated),
    ],
    verify: (_) {
      verify(() => sessionManager.wipeSession()).called(1);
      verifyNever(
        () => sessionManager.primeCurrentUser(
          any(),
          schoolId: any(named: 'schoolId'),
          permissions: any(named: 'permissions'),
        ),
      );
    },
  );
}
