import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:school_app_flutter/features/auth/data/models/login_request_model.dart';
import 'package:school_app_flutter/features/auth/data/models/login_response_model.dart';
import 'package:school_app_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockLocal extends Mock implements AuthLocalDataSource {}

class _MockSessionManager extends Mock implements AuthSessionManager {}

const _schoolId = '8a9e5f7b-7f8f-4e39-9f89-c0744c5c9f20';

const _loginJson = <String, dynamic>{
  'accessToken': 'access',
  'tokenType': 'Bearer',
  'expiresIn': 3600,
  'refreshToken': 'refresh',
  'refreshExpiresIn': 7776000,
  'userVersion': 1,
  'user': <String, dynamic>{
    'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
    'email': 'direction@ecole.cd',
    'firstName': 'Amina',
    'lastName': 'Kalala',
    'role': 'DIRECTOR',
    'schoolId': _schoolId,
  },
};

/// Au login en ligne, l'école s'attache AVANT que rien ne soit persisté, et son
/// échec n'est pas avalé comme l'ancrage offline (MULTI_ECOLE_PLAN.md §10.2).
void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockSessionManager sessionManager;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const LoginRequestModel(email: 'a@b.cd', password: 'x'),
    );
    registerFallbackValue(
      const AuthSession(
        accessToken: '',
        tokenType: 'Bearer',
        expiresIn: 0,
        user: AuthenticatedUser(
          email: '',
          firstName: '',
          lastName: '',
          role: '',
          schoolId: '',
        ),
      ),
    );
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    sessionManager = _MockSessionManager();
    when(
      () => remote.login(any()),
    ).thenAnswer((_) async => LoginResponseModel.fromJson(_loginJson));
    when(() => local.saveSession(any())).thenAnswer((_) async {});
    when(
      () => sessionManager.persistOnlineLogin(any(), any()),
    ).thenAnswer((_) async {});
    repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      sessionManager: sessionManager,
    );
  });

  test('l école s attache avant que la session soit persistée', () async {
    when(() => sessionManager.attachSchool(any())).thenAnswer((_) async {});

    final result = await repository.login(
      email: 'direction@ecole.cd',
      password: 'secret',
    );

    expect(result.isRight(), isTrue);
    verifyInOrder([
      () => sessionManager.attachSchool(_schoolId),
      () => local.saveSession(any()),
    ]);
  });

  test('la base de l école ne s ouvre pas : échec de stockage, et rien n est '
      'persisté', () async {
    when(
      () => sessionManager.attachSchool(any()),
    ).thenThrow(StateError('fichier illisible'));

    final result = await repository.login(
      email: 'direction@ecole.cd',
      password: 'secret',
    );

    expect(
      result.fold((failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );
    verifyNever(() => local.saveSession(any()));
    verifyNever(() => sessionManager.persistOnlineLogin(any(), any()));
  });
}
