import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/clear_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_current_year_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_previous_year_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/save_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';

class _MockGetRemoteCurrent extends Mock
    implements GetRemoteBootstrapCurrentYearUseCase {}

class _MockGetRemotePrevious extends Mock
    implements GetRemoteBootstrapPreviousYearUseCase {}

class _MockGetLocal extends Mock implements GetLocalBootstrapUseCase {}

class _MockSaveLocal extends Mock implements SaveLocalBootstrapUseCase {}

class _MockClearLocal extends Mock implements ClearLocalBootstrapUseCase {}

void main() {
  late _MockGetRemoteCurrent getRemoteCurrent;
  late _MockGetRemotePrevious getRemotePrevious;
  late _MockGetLocal getLocal;
  late _MockSaveLocal saveLocal;
  late _MockClearLocal clearLocal;

  setUp(() {
    getRemoteCurrent = _MockGetRemoteCurrent();
    getRemotePrevious = _MockGetRemotePrevious();
    getLocal = _MockGetLocal();
    saveLocal = _MockSaveLocal();
    clearLocal = _MockClearLocal();
  });

  BootstrapBloc build() => BootstrapBloc(
    getRemoteBootstrapUseCase: getRemoteCurrent,
    getRemoteBootstrapPreviousYearUseCase: getRemotePrevious,
    getLocalBootstrapUseCase: getLocal,
    saveLocalBootstrapUseCase: saveLocal,
    clearLocalBootstrapUseCase: clearLocal,
  );

  blocTest<BootstrapBloc, BootstrapState>(
    '401 sur le bootstrap distant → sessionExpired = true',
    setUp: () => when(() => getRemoteCurrent()).thenAnswer(
      (_) async => const Left(InvalidCredentialsFailure('unauthorized')),
    ),
    build: build,
    act: (bloc) => bloc.add(const BootstrapRemoteCurrentYearRequested()),
    expect: () => [
      isA<BootstrapState>().having(
        (s) => s.status,
        'status',
        BootstrapLoadStatus.loading,
      ),
      isA<BootstrapState>()
          .having((s) => s.status, 'status', BootstrapLoadStatus.failure)
          .having((s) => s.sessionExpired, 'sessionExpired', isTrue),
    ],
  );

  blocTest<BootstrapBloc, BootstrapState>(
    'erreur réseau (non-auth) → sessionExpired reste false',
    setUp: () => when(
      () => getRemoteCurrent(),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline'))),
    build: build,
    act: (bloc) => bloc.add(const BootstrapRemoteCurrentYearRequested()),
    expect: () => [
      isA<BootstrapState>().having(
        (s) => s.status,
        'status',
        BootstrapLoadStatus.loading,
      ),
      isA<BootstrapState>()
          .having((s) => s.status, 'status', BootstrapLoadStatus.failure)
          .having((s) => s.sessionExpired, 'sessionExpired', isFalse),
    ],
  );
}
