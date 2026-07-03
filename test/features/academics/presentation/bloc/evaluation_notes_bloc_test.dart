import 'package:bloc_test/bloc_test.dart';
// `dartz` et `flutter_test` exportent un type `Evaluation` : on les masque au
// profit de notre entité domaine.
import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/evaluation_notes_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/evaluation_notes_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/evaluation_notes_state.dart';

class MockGetNotesElevesUseCase extends Mock implements GetNotesElevesUseCase {}

/// Failure non mappée explicitement : exerce la branche par défaut du switch.
class _UnmappedFailure extends Failure {
  const _UnmappedFailure() : super('unmapped');
}

const tEvaluationId = 'eval-1';

/// En-tête fourni par l'écran appelant. Non `const` : `DateTime` ne l'est pas.
final tEvaluation = Evaluation(
  id: tEvaluationId,
  coursId: 'cours-1',
  type: TypeEvaluation.interro,
  date: DateTime(2025, 5, 12),
  maxPoints: 20,
  poids: 1,
  sousPeriodeId: 'sp-1',
);

/// Liste mixte couvrant chaque `StatutNote` + un élève non encore noté
/// (`statut`/`pointsObtenus` nuls). Déjà triée par nom (comme le backend).
const tNotes = <NoteEleve>[
  NoteEleve(
    studentId: 's1',
    firstName: 'Alice',
    lastName: 'Bernard',
    pointsObtenus: 15.0,
    statut: StatutNote.notee,
  ),
  NoteEleve(
    studentId: 's2',
    firstName: 'Bruno',
    lastName: 'Colin',
    statut: StatutNote.absentJustifie,
  ),
  NoteEleve(
    studentId: 's3',
    firstName: 'Chloé',
    lastName: 'Denis',
    statut: StatutNote.absentNonJustifie,
  ),
  NoteEleve(
    studentId: 's4',
    firstName: 'David',
    lastName: 'Evrard',
    statut: StatutNote.enAttente,
  ),
  // Élève non noté : les deux champs restent nuls (≠ StatutNote.unknown).
  NoteEleve(studentId: 's5', firstName: 'Emma', lastName: 'Faure'),
];

void main() {
  late MockGetNotesElevesUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetNotesElevesUseCase();
  });

  EvaluationNotesBloc buildBloc() =>
      EvaluationNotesBloc(getNotesElevesUseCase: mockUseCase);

  group('EvaluationNotesRequested — succès', () {
    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'pose l\'en-tête dès le loading puis émet success avec la liste '
      '(élèves notés ET non notés)',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Right(tNotes));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        EvaluationNotesRequested(
          evaluationId: tEvaluationId,
          evaluation: tEvaluation,
        ),
      ),
      expect: () => [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          evaluation: tEvaluation,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.success,
          evaluation: tEvaluation,
          notes: tNotes,
          errorType: EvaluationNotesErrorType.none,
        ),
      ],
      verify: (_) {
        verify(() => mockUseCase(tEvaluationId)).called(1);
      },
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'émet success sans en-tête quand aucune Evaluation n\'est fournie '
      '(mode dégradé, evaluation reste null)',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Right(tNotes));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.success,
          notes: tNotes,
          errorType: EvaluationNotesErrorType.none,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'émet success avec une liste vide (aucun élève renvoyé)',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Right(<NoteEleve>[]));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.success,
          errorType: EvaluationNotesErrorType.none,
        ),
      ],
    );
  });

  group('EvaluationNotesRequested — mapping des Failure', () {
    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'maps NotFoundFailure (404) to notFound error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          errorType: EvaluationNotesErrorType.notFound,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'maps NetworkFailure to network error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          errorType: EvaluationNotesErrorType.network,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'maps UnauthorizedFailure (403) to forbidden error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(UnauthorizedFailure()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          errorType: EvaluationNotesErrorType.forbidden,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'maps InvalidCredentialsFailure (401) to invalidCredentials error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          errorType: EvaluationNotesErrorType.invalidCredentials,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'maps ValidationFailure to validation error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(ValidationFailure()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          errorType: EvaluationNotesErrorType.validation,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'maps ServerFailure (5xx) to server error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          errorType: EvaluationNotesErrorType.server,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'maps StorageFailure to storage error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(StorageFailure()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          errorType: EvaluationNotesErrorType.storage,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'maps AuthFailure to auth error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(AuthFailure()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          errorType: EvaluationNotesErrorType.auth,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'maps an unmapped Failure to unknown error type (branche par défaut)',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(_UnmappedFailure()));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const EvaluationNotesRequested(evaluationId: tEvaluationId)),
      expect: () => const [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          errorType: EvaluationNotesErrorType.unknown,
        ),
      ],
    );

    blocTest<EvaluationNotesBloc, EvaluationNotesState>(
      'conserve l\'en-tête fourni même quand la liste échoue '
      '(evaluation posée au loading reste présente sur failure)',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        EvaluationNotesRequested(
          evaluationId: tEvaluationId,
          evaluation: tEvaluation,
        ),
      ),
      expect: () => [
        EvaluationNotesState(
          status: EvaluationNotesStatus.loading,
          evaluation: tEvaluation,
          errorType: EvaluationNotesErrorType.none,
        ),
        EvaluationNotesState(
          status: EvaluationNotesStatus.failure,
          evaluation: tEvaluation,
          errorType: EvaluationNotesErrorType.network,
        ),
      ],
    );
  });
}
