import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
// `dartz` et `flutter_test` exportent un type `Evaluation` : on les masque au
// profit de notre entité domaine.
import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/create_evaluation_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_state.dart';

class MockCreateEvaluationUseCase extends Mock
    implements CreateEvaluationUseCase {}

/// Failure non mappée explicitement : exerce la branche par défaut du switch.
class _UnmappedFailure extends Failure {
  const _UnmappedFailure() : super('unmapped');
}

void main() {
  late MockCreateEvaluationUseCase mockUseCase;

  const tCoursId = 'cours-1';
  final tDate = DateTime(2025, 11, 10);
  final tRequest = CreateEvaluationRequest.examen(
    date: tDate,
    maxPoints: 20,
    periodeScolaireId: 'periode-1',
  );
  final tEvaluation = Evaluation(
    id: 'ev-1',
    coursId: tCoursId,
    type: TypeEvaluation.examen,
    date: tDate,
    maxPoints: 20,
    poids: 1,
    periodeScolaireId: 'periode-1',
  );

  setUpAll(() {
    registerFallbackValue(tRequest);
  });

  late Completer<Either<Failure, Evaluation>> completer;

  setUp(() {
    mockUseCase = MockCreateEvaluationUseCase();
  });

  CreateEvaluationBloc buildBloc() =>
      CreateEvaluationBloc(createEvaluationUseCase: mockUseCase);

  CreateEvaluationSubmitted submit() =>
      CreateEvaluationSubmitted(coursId: tCoursId, request: tRequest);

  test('état initial : CreateEvaluationStatus.initial', () {
    expect(buildBloc().state, const CreateEvaluationState());
  });

  group('CreateEvaluationSubmitted — succès', () {
    blocTest<CreateEvaluationBloc, CreateEvaluationState>(
      'emits inProgress then success portant l\'évaluation créée',
      setUp: () {
        when(
          () => mockUseCase(any(), any()),
        ).thenAnswer((_) async => Right(tEvaluation));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(submit()),
      expect: () => [
        const CreateEvaluationState(status: CreateEvaluationStatus.inProgress),
        CreateEvaluationState(
          status: CreateEvaluationStatus.success,
          createdEvaluation: tEvaluation,
        ),
      ],
      verify: (_) {
        verify(() => mockUseCase(tCoursId, tRequest)).called(1);
      },
    );
  });

  group('CreateEvaluationSubmitted — mapping des erreurs', () {
    final cases = <(Failure, CreateEvaluationErrorType, String)>[
      (
        const NetworkFailure(),
        CreateEvaluationErrorType.network,
        'Network error occurred',
      ),
      (
        const NotFoundFailure(),
        CreateEvaluationErrorType.notFound,
        'Resource not found',
      ),
      (
        const ValidationFailure(),
        CreateEvaluationErrorType.validation,
        'Invalid request data',
      ),
      (
        const UnauthorizedFailure(),
        CreateEvaluationErrorType.forbidden,
        'Unauthorized',
      ),
      (
        const InvalidCredentialsFailure(),
        CreateEvaluationErrorType.invalidCredentials,
        'Invalid email or password',
      ),
      (
        const ServerFailure(),
        CreateEvaluationErrorType.server,
        'Server error occurred',
      ),
      (
        const StorageFailure(),
        CreateEvaluationErrorType.storage,
        'Storage error occurred',
      ),
      (
        const AuthFailure(),
        CreateEvaluationErrorType.auth,
        'Authentication error',
      ),
      (const _UnmappedFailure(), CreateEvaluationErrorType.unknown, 'unmapped'),
    ];

    for (final (failure, errorType, message) in cases) {
      blocTest<CreateEvaluationBloc, CreateEvaluationState>(
        'mappe ${failure.runtimeType} -> $errorType',
        setUp: () {
          when(
            () => mockUseCase(any(), any()),
          ).thenAnswer((_) async => Left(failure));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(submit()),
        expect: () => [
          const CreateEvaluationState(
            status: CreateEvaluationStatus.inProgress,
          ),
          CreateEvaluationState(
            status: CreateEvaluationStatus.failure,
            errorType: errorType,
            errorMessage: message,
          ),
        ],
      );
    }
  });

  group('garde anti-double-envoi', () {
    blocTest<CreateEvaluationBloc, CreateEvaluationState>(
      'ignore une soumission tant qu\'une création est en cours',
      seed: () => const CreateEvaluationState(
        status: CreateEvaluationStatus.inProgress,
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(submit()),
      expect: () => const <CreateEvaluationState>[],
      verify: (_) {
        verifyNever(() => mockUseCase(any(), any()));
      },
    );

    blocTest<CreateEvaluationBloc, CreateEvaluationState>(
      'deux Submitted rapprochés -> un seul appel usecase (non-réentrance)',
      setUp: () {
        // L'appel reste en cours (future non complétée) le temps que le 2e
        // Submitted soit traité, reproduisant la vraie course de double-clic.
        completer = Completer<Either<Failure, Evaluation>>();
        when(
          () => mockUseCase(any(), any()),
        ).thenAnswer((_) => completer.future);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(submit());
        bloc.add(submit()); // doit être ignoré (création déjà en cours)
        // On laisse les deux events se faire traiter (le 1er reste en vol sur
        // la future non complétée, le 2e tombe dans la garde) AVANT de
        // compléter l'appel.
        await Future<void>.delayed(Duration.zero);
        completer.complete(Right(tEvaluation));
      },
      expect: () => [
        const CreateEvaluationState(status: CreateEvaluationStatus.inProgress),
        CreateEvaluationState(
          status: CreateEvaluationStatus.success,
          createdEvaluation: tEvaluation,
        ),
      ],
      verify: (_) {
        verify(() => mockUseCase(tCoursId, tRequest)).called(1);
      },
    );
  });

  group('CreateEvaluationReset', () {
    blocTest<CreateEvaluationBloc, CreateEvaluationState>(
      'réinitialise vers l\'état initial',
      seed: () => CreateEvaluationState(
        status: CreateEvaluationStatus.success,
        createdEvaluation: tEvaluation,
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const CreateEvaluationReset()),
      expect: () => const [CreateEvaluationState()],
    );
  });
}
