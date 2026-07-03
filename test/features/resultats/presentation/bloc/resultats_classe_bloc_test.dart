import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_eleve_ligne.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe_stats.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_resultats_classe_usecase.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

class MockGetResultatsClasseUseCase extends Mock
    implements GetResultatsClasseUseCase {}

/// Failure non mappée explicitement : exerce la branche par défaut du switch.
class _UnmappedFailure extends Failure {
  const _UnmappedFailure() : super('unmapped');
}

const _tClasseNonEmpty = ResultatsClasse(
  classroomId: 'c',
  periodeScolaireId: 'p',
  periodeOrdre: 1,
  sousPeriodes: [],
  stats: ResultatsClasseStats(
    effectif: 1,
    seuil: 50,
    reussites: 0,
    echecs: 0,
    nonClasses: 0,
  ),
  lignes: [
    ResultatEleveLigne(
      studentId: 's',
      nom: 'D',
      prenom: 'J',
      nonClasse: false,
      pourcentages: [],
    ),
  ],
);

const _tClasseEmpty = ResultatsClasse(
  classroomId: 'c',
  periodeScolaireId: 'p',
  periodeOrdre: 1,
  sousPeriodes: [],
  stats: ResultatsClasseStats(
    effectif: 0,
    seuil: 50,
    reussites: 0,
    echecs: 0,
    nonClasses: 0,
  ),
  lignes: [],
);

const _event = ResultatsClasseRequested(
  classroomId: 'c',
  periodeScolaireId: 'p',
);

void main() {
  late MockGetResultatsClasseUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(
      const GetResultatsClasseParams(classroomId: '', periodeScolaireId: ''),
    );
  });

  setUp(() {
    mockUseCase = MockGetResultatsClasseUseCase();
  });

  ResultatsClasseBloc buildBloc() =>
      ResultatsClasseBloc(getResultatsClasse: mockUseCase);

  blocTest<ResultatsClasseBloc, ResultatsClasseState>(
    'loading puis success (données non vides)',
    setUp: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Right(_tClasseNonEmpty));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(_event),
    expect: () => const [
      ResultatsClasseState(
        status: ResultatsClasseStatus.loading,
        errorType: ResultatsErrorType.none,
      ),
      ResultatsClasseState(
        status: ResultatsClasseStatus.success,
        resultats: _tClasseNonEmpty,
        errorType: ResultatsErrorType.none,
      ),
    ],
    verify: (_) => verify(() => mockUseCase(any())).called(1),
  );

  blocTest<ResultatsClasseBloc, ResultatsClasseState>(
    'loading puis empty (lignes vides / effectif 0), pas une erreur',
    setUp: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Right(_tClasseEmpty));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(_event),
    expect: () => const [
      ResultatsClasseState(
        status: ResultatsClasseStatus.loading,
        errorType: ResultatsErrorType.none,
      ),
      ResultatsClasseState(
        status: ResultatsClasseStatus.empty,
        resultats: _tClasseEmpty,
        errorType: ResultatsErrorType.none,
      ),
    ],
  );

  // Couverture exhaustive de _mapFailureToErrorType.
  final failureCases = <Failure, ResultatsErrorType>{
    const NetworkFailure(): ResultatsErrorType.network,
    const NotFoundFailure(): ResultatsErrorType.notFound,
    const ValidationFailure(): ResultatsErrorType.validation,
    const UnauthorizedFailure(): ResultatsErrorType.forbidden,
    const InvalidCredentialsFailure(): ResultatsErrorType.invalidCredentials,
    const ServerFailure(): ResultatsErrorType.server,
    const StorageFailure(): ResultatsErrorType.storage,
    const AuthFailure(): ResultatsErrorType.auth,
    const _UnmappedFailure(): ResultatsErrorType.unknown,
  };

  for (final entry in failureCases.entries) {
    blocTest<ResultatsClasseBloc, ResultatsClasseState>(
      'mappe ${entry.key.runtimeType} -> ${entry.value}',
      setUp: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Left(entry.key));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(_event),
      expect: () => [
        const ResultatsClasseState(
          status: ResultatsClasseStatus.loading,
          errorType: ResultatsErrorType.none,
        ),
        ResultatsClasseState(
          status: ResultatsClasseStatus.failure,
          errorType: entry.value,
        ),
      ],
    );
  }
}
