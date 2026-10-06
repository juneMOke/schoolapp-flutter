import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/get_copie_log_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/log_copie_diffusion_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_state.dart';

class _MockGetLog extends Mock implements GetCopieLogUseCase {}

class _MockLog extends Mock implements LogCopieDiffusionUseCase {}

void main() {
  late _MockGetLog getLog;
  late _MockLog log;

  final printed = CopieDiffusion(
    id: 'l-1',
    kind: CopieKind.print,
    corrige: false,
    occurredAt: DateTime.utc(2026, 10, 6),
  );
  final shared = CopieDiffusion(
    id: 'l-2',
    kind: CopieKind.share,
    canal: CopieCanal.systeme,
    corrige: true,
    occurredAt: DateTime.utc(2026, 10, 7),
  );

  setUp(() {
    getLog = _MockGetLog();
    log = _MockLog();
  });

  CopieBloc build() =>
      CopieBloc(getCopieLogUseCase: getLog, logCopieDiffusionUseCase: log);

  blocTest<CopieBloc, CopieState>(
    'charge le journal',
    setUp: () =>
        when(() => getLog('ev-1')).thenAnswer((_) async => Right([printed])),
    build: build,
    act: (bloc) => bloc.add(const CopieLogRequested('ev-1')),
    expect: () => [
      CopieState(log: [printed]),
    ],
  );

  blocTest<CopieBloc, CopieState>(
    'un partage part par la feuille du système, en tête du journal',
    setUp: () => when(
      () => log(
        'ev-1',
        kind: CopieKind.share,
        canal: CopieCanal.systeme,
        corrige: true,
      ),
    ).thenAnswer((_) async => Right(shared)),
    build: build,
    seed: () => CopieState(log: [printed]),
    act: (bloc) => bloc.add(
      const CopieDiffused(
        evaluationId: 'ev-1',
        kind: CopieKind.share,
        corrige: true,
      ),
    ),
    expect: () => [
      CopieState(log: [shared, printed]),
    ],
    verify: (bloc) {
      expect(bloc.state.printCount, 1);
      expect(bloc.state.shareCount, 1);
    },
  );

  blocTest<CopieBloc, CopieState>(
    'un journal illisible ne change rien',
    setUp: () => when(
      () => getLog('ev-1'),
    ).thenAnswer((_) async => const Left(StorageFailure())),
    build: build,
    act: (bloc) => bloc.add(const CopieLogRequested('ev-1')),
    expect: () => <CopieState>[],
  );
}
