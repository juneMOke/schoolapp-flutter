import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/saisir_note_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_state.dart';

class MockGetNotesElevesUseCase extends Mock implements GetNotesElevesUseCase {}

class MockSaisirNoteUseCase extends Mock implements SaisirNoteUseCase {}

/// Failure non mappée explicitement : exerce la branche par défaut du switch.
class _UnmappedFailure extends Failure {
  const _UnmappedFailure() : super('unmapped');
}

void main() {
  late MockGetNotesElevesUseCase mockGetNotes;
  late MockSaisirNoteUseCase mockSaisirNote;
  // Utilisé par le test de concurrence inter-lignes : maintient la saisie de s1
  // « en vol » pendant que s2 se sauve.
  late Completer<Either<Failure, NoteEvaluation>> s1Completer;

  const tEvaluationId = 'ev1';
  const tMaxPoints = 20.0;
  const tStudentId = 's1';
  const tStudentId2 = 's2';
  const tNote = NoteEleve(
    studentId: tStudentId,
    firstName: 'Jean',
    lastName: 'Dupont',
  );
  const tNote2 = NoteEleve(
    studentId: tStudentId2,
    firstName: 'Awa',
    lastName: 'Kone',
  );
  // Ligne portant DÉJÀ une note NOTEE avec des points (pour la non-régression
  // « passage NOTEE→ABSENT remet les points à null »).
  const tNoteNoted15 = NoteEleve(
    studentId: tStudentId,
    firstName: 'Jean',
    lastName: 'Dupont',
    pointsObtenus: 15,
    statut: StatutNote.notee,
  );
  const tNoteAbsent = NoteEleve(
    studentId: tStudentId,
    firstName: 'Jean',
    lastName: 'Dupont',
    statut: StatutNote.absentJustifie,
  );
  // Notes fusionnées attendues après sauvegarde (points dans [0, maxPoints]).
  const tNote1Saved10 = NoteEleve(
    studentId: tStudentId,
    firstName: 'Jean',
    lastName: 'Dupont',
    pointsObtenus: 10,
    statut: StatutNote.notee,
  );
  const tNote1Saved15 = NoteEleve(
    studentId: tStudentId,
    firstName: 'Jean',
    lastName: 'Dupont',
    pointsObtenus: 15,
    statut: StatutNote.notee,
  );
  const tNote2Saved12 = NoteEleve(
    studentId: tStudentId2,
    firstName: 'Awa',
    lastName: 'Kone',
    pointsObtenus: 12,
    statut: StatutNote.notee,
  );

  setUpAll(() {
    registerFallbackValue(
      SaisirNoteRequest.forStatut(
        studentId: tStudentId,
        statut: StatutNote.enAttente,
      ),
    );
  });

  setUp(() {
    mockGetNotes = MockGetNotesElevesUseCase();
    mockSaisirNote = MockSaisirNoteUseCase();
  });

  SaisieNotesBloc buildBloc() => SaisieNotesBloc(
    getNotesElevesUseCase: mockGetNotes,
    saisirNoteUseCase: mockSaisirNote,
  );

  // Grille chargée avec une ligne idle et maxPoints connu.
  SaisieNotesState loadedState({
    List<NoteEleveRow> rows = const [NoteEleveRow(note: tNote)],
    double maxPoints = tMaxPoints,
  }) => SaisieNotesState(
    gridStatus: SaisieNotesGridStatus.loaded,
    maxPoints: maxPoints,
    rows: rows,
  );

  test('état initial', () {
    expect(buildBloc().state, const SaisieNotesState());
  });

  group('NotesElevesLoaded — chargement de la grille', () {
    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'succès: loading -> loaded (rows idle) + maxPoints mémorisé',
      setUp: () {
        when(
          () => mockGetNotes(any()),
        ).thenAnswer((_) async => const Right([tNote]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const NotesElevesLoaded(
          evaluationId: tEvaluationId,
          maxPoints: tMaxPoints,
        ),
      ),
      expect: () => [
        const SaisieNotesState(
          gridStatus: SaisieNotesGridStatus.loading,
          maxPoints: tMaxPoints,
        ),
        const SaisieNotesState(
          gridStatus: SaisieNotesGridStatus.loaded,
          maxPoints: tMaxPoints,
          rows: [NoteEleveRow(note: tNote)],
        ),
      ],
      verify: (_) {
        verify(() => mockGetNotes(tEvaluationId)).called(1);
      },
    );

    final loadCases = <(Failure, SaisieNotesErrorType)>[
      (const NetworkFailure(), SaisieNotesErrorType.network),
      (const NotFoundFailure(), SaisieNotesErrorType.notFound),
      (const UnauthorizedFailure(), SaisieNotesErrorType.forbidden),
      (
        const InvalidCredentialsFailure(),
        SaisieNotesErrorType.invalidCredentials,
      ),
      (const _UnmappedFailure(), SaisieNotesErrorType.unknown),
    ];

    for (final (failure, errorType) in loadCases) {
      blocTest<SaisieNotesBloc, SaisieNotesState>(
        'échec: ${failure.runtimeType} -> loadError($errorType)',
        setUp: () {
          when(
            () => mockGetNotes(any()),
          ).thenAnswer((_) async => Left(failure));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(
          const NotesElevesLoaded(
            evaluationId: tEvaluationId,
            maxPoints: tMaxPoints,
          ),
        ),
        expect: () => [
          const SaisieNotesState(
            gridStatus: SaisieNotesGridStatus.loading,
            maxPoints: tMaxPoints,
          ),
          SaisieNotesState(
            gridStatus: SaisieNotesGridStatus.loadError,
            gridErrorType: errorType,
            gridErrorMessage: failure.message,
            maxPoints: tMaxPoints,
          ),
        ],
      );
    }
  });

  group('NoteSaisie — succès', () {
    const tMerged = NoteEleve(
      studentId: tStudentId,
      firstName: 'Jean',
      lastName: 'Dupont',
      pointsObtenus: 15,
      statut: StatutNote.notee,
    );

    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'NOTEE valide: ligne saving -> saved (note persistée fusionnée)',
      setUp: () {
        when(() => mockSaisirNote(any(), any())).thenAnswer(
          (_) async => const Right(
            NoteEvaluation(
              id: 'n1',
              evaluationId: tEvaluationId,
              studentId: tStudentId,
              pointsObtenus: 15,
              statut: StatutNote.notee,
            ),
          ),
        );
      },
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(
        const NoteSaisie(
          evaluationId: tEvaluationId,
          studentId: tStudentId,
          statut: StatutNote.notee,
          pointsObtenus: 15,
        ),
      ),
      expect: () => [
        loadedState(
          rows: const [
            NoteEleveRow(note: tNote, saveStatus: RowSaveStatus.saving),
          ],
        ),
        loadedState(
          rows: const [
            NoteEleveRow(note: tMerged, saveStatus: RowSaveStatus.saved),
          ],
        ),
      ],
      verify: (_) {
        verify(() => mockSaisirNote(tEvaluationId, any())).called(1);
      },
    );

    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'ABSENT_JUSTIFIE: sauve sans points (règle 2) et fusionne le statut',
      setUp: () {
        when(() => mockSaisirNote(any(), any())).thenAnswer(
          (_) async => const Right(
            NoteEvaluation(
              id: 'n2',
              evaluationId: tEvaluationId,
              studentId: tStudentId,
              statut: StatutNote.absentJustifie,
            ),
          ),
        );
      },
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(
        const NoteSaisie(
          evaluationId: tEvaluationId,
          studentId: tStudentId,
          statut: StatutNote.absentJustifie,
        ),
      ),
      expect: () => [
        loadedState(
          rows: const [
            NoteEleveRow(note: tNote, saveStatus: RowSaveStatus.saving),
          ],
        ),
        loadedState(
          rows: const [
            NoteEleveRow(
              note: NoteEleve(
                studentId: tStudentId,
                firstName: 'Jean',
                lastName: 'Dupont',
                statut: StatutNote.absentJustifie,
              ),
              saveStatus: RowSaveStatus.saved,
            ),
          ],
        ),
      ],
      verify: (_) {
        final captured =
            verify(
                  () => mockSaisirNote(tEvaluationId, captureAny()),
                ).captured.single
                as SaisirNoteRequest;
        expect(captured.statut, StatutNote.absentJustifie);
        expect(captured.pointsObtenus, isNull);
      },
    );

    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'NOTEE(15) -> ABSENT_JUSTIFIE : points remis à null dans la row '
      '(non-régression)',
      setUp: () {
        when(() => mockSaisirNote(any(), any())).thenAnswer(
          (_) async => const Right(
            NoteEvaluation(
              id: 'n3',
              evaluationId: tEvaluationId,
              studentId: tStudentId,
              statut: StatutNote.absentJustifie,
            ),
          ),
        );
      },
      build: buildBloc,
      // La ligne porte déjà une note NOTEE avec 15 points.
      seed: () => loadedState(rows: const [NoteEleveRow(note: tNoteNoted15)]),
      act: (bloc) => bloc.add(
        const NoteSaisie(
          evaluationId: tEvaluationId,
          studentId: tStudentId,
          statut: StatutNote.absentJustifie,
        ),
      ),
      expect: () => [
        loadedState(
          rows: const [
            NoteEleveRow(note: tNoteNoted15, saveStatus: RowSaveStatus.saving),
          ],
        ),
        loadedState(
          rows: const [
            NoteEleveRow(note: tNoteAbsent, saveStatus: RowSaveStatus.saved),
          ],
        ),
      ],
      verify: (bloc) {
        // Preuve du reset : les points ont bien disparu de la row.
        expect(bloc.state.rowFor(tStudentId)!.note.pointsObtenus, isNull);
        expect(
          bloc.state.rowFor(tStudentId)!.note.statut,
          StatutNote.absentJustifie,
        );
      },
    );
  });

  group('NoteSaisie — validation locale (aucun appel réseau)', () {
    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'NOTEE sans points -> ligne error(validation), pas d\'appel',
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(
        const NoteSaisie(
          evaluationId: tEvaluationId,
          studentId: tStudentId,
          statut: StatutNote.notee,
        ),
      ),
      expect: () => [
        loadedState(
          rows: const [
            NoteEleveRow(
              note: tNote,
              saveStatus: RowSaveStatus.error,
              errorType: SaisieNotesErrorType.validation,
            ),
          ],
        ),
      ],
      verify: (_) {
        verifyNever(() => mockSaisirNote(any(), any()));
      },
    );

    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'NOTEE points > maxPoints -> ligne error(validation), pas d\'appel',
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(
        const NoteSaisie(
          evaluationId: tEvaluationId,
          studentId: tStudentId,
          statut: StatutNote.notee,
          pointsObtenus: 21, // > maxPoints (20)
        ),
      ),
      expect: () => [
        loadedState(
          rows: const [
            NoteEleveRow(
              note: tNote,
              saveStatus: RowSaveStatus.error,
              errorType: SaisieNotesErrorType.validation,
            ),
          ],
        ),
      ],
      verify: (_) {
        verifyNever(() => mockSaisirNote(any(), any()));
      },
    );

    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'NOTEE points < 0 -> ligne error(validation), pas d\'appel',
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(
        const NoteSaisie(
          evaluationId: tEvaluationId,
          studentId: tStudentId,
          statut: StatutNote.notee,
          pointsObtenus: -1,
        ),
      ),
      expect: () => [
        loadedState(
          rows: const [
            NoteEleveRow(
              note: tNote,
              saveStatus: RowSaveStatus.error,
              errorType: SaisieNotesErrorType.validation,
            ),
          ],
        ),
      ],
      verify: (_) {
        verifyNever(() => mockSaisirNote(any(), any()));
      },
    );
  });

  group('NoteSaisie — mapping des erreurs par ligne', () {
    final saveCases = <(Failure, SaisieNotesErrorType, String)>[
      (
        const ValidationFailure(),
        SaisieNotesErrorType.validation,
        'Invalid request data',
      ),
      (
        const NotFoundFailure(),
        SaisieNotesErrorType.notFound,
        'Resource not found',
      ),
      (
        const NetworkFailure(),
        SaisieNotesErrorType.network,
        'Network error occurred',
      ),
    ];

    for (final (failure, errorType, message) in saveCases) {
      blocTest<SaisieNotesBloc, SaisieNotesState>(
        '${failure.runtimeType} -> ligne error($errorType)',
        setUp: () {
          when(
            () => mockSaisirNote(any(), any()),
          ).thenAnswer((_) async => Left(failure));
        },
        build: buildBloc,
        seed: loadedState,
        act: (bloc) => bloc.add(
          const NoteSaisie(
            evaluationId: tEvaluationId,
            studentId: tStudentId,
            statut: StatutNote.notee,
            pointsObtenus: 15,
          ),
        ),
        expect: () => [
          loadedState(
            rows: const [
              NoteEleveRow(note: tNote, saveStatus: RowSaveStatus.saving),
            ],
          ),
          loadedState(
            rows: [
              NoteEleveRow(
                note: tNote,
                saveStatus: RowSaveStatus.error,
                errorType: errorType,
                errorMessage: message,
              ),
            ],
          ),
        ],
      );
    }
  });

  group('NoteSaisie — anti-course & garde-fous', () {
    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'ligne déjà saving : nouvelle saisie ignorée (aucun appel)',
      build: buildBloc,
      seed: () => loadedState(
        rows: const [
          NoteEleveRow(note: tNote, saveStatus: RowSaveStatus.saving),
        ],
      ),
      act: (bloc) => bloc.add(
        const NoteSaisie(
          evaluationId: tEvaluationId,
          studentId: tStudentId,
          statut: StatutNote.notee,
          pointsObtenus: 15,
        ),
      ),
      expect: () => const <SaisieNotesState>[],
      verify: (_) {
        verifyNever(() => mockSaisirNote(any(), any()));
      },
    );

    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'deux saisies rapprochées sur la même ligne -> un seul appel',
      setUp: () {
        final completer = Completer<Either<Failure, NoteEvaluation>>();
        when(() => mockSaisirNote(any(), any())).thenAnswer((_) {
          // Complète après coup pour que la 2e saisie tombe dans la garde.
          Future<void>.delayed(Duration.zero).then((_) {
            completer.complete(
              const Right(
                NoteEvaluation(
                  id: 'n1',
                  evaluationId: tEvaluationId,
                  studentId: tStudentId,
                  pointsObtenus: 15,
                  statut: StatutNote.notee,
                ),
              ),
            );
          });
          return completer.future;
        });
      },
      build: buildBloc,
      seed: loadedState,
      act: (bloc) {
        bloc.add(
          const NoteSaisie(
            evaluationId: tEvaluationId,
            studentId: tStudentId,
            statut: StatutNote.notee,
            pointsObtenus: 15,
          ),
        );
        bloc.add(
          const NoteSaisie(
            evaluationId: tEvaluationId,
            studentId: tStudentId,
            statut: StatutNote.notee,
            pointsObtenus: 15,
          ),
        );
      },
      expect: () => [
        loadedState(
          rows: const [
            NoteEleveRow(note: tNote, saveStatus: RowSaveStatus.saving),
          ],
        ),
        loadedState(
          rows: const [
            NoteEleveRow(
              note: NoteEleve(
                studentId: tStudentId,
                firstName: 'Jean',
                lastName: 'Dupont',
                pointsObtenus: 15,
                statut: StatutNote.notee,
              ),
              saveStatus: RowSaveStatus.saved,
            ),
          ],
        ),
      ],
      verify: (_) {
        verify(() => mockSaisirNote(any(), any())).called(1);
      },
    );

    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'élève hors grille : saisie ignorée (aucun appel, aucun état)',
      build: buildBloc,
      seed: loadedState,
      act: (bloc) => bloc.add(
        const NoteSaisie(
          evaluationId: tEvaluationId,
          studentId: 's-inconnu',
          statut: StatutNote.notee,
          pointsObtenus: 15,
        ),
      ),
      expect: () => const <SaisieNotesState>[],
      verify: (_) {
        verifyNever(() => mockSaisirNote(any(), any()));
      },
    );
  });

  group('NoteSaisie — isolation & concurrence inter-lignes', () {
    // Grille à DEUX élèves : le cœur du design « statut par ligne ».
    SaisieNotesState twoRowState() => loadedState(
      rows: const [
        NoteEleveRow(note: tNote),
        NoteEleveRow(note: tNote2),
      ],
    );

    blocTest<SaisieNotesBloc, SaisieNotesState>(
      'sauver s1 laisse la ligne s2 intacte (isolation withRow)',
      setUp: () {
        when(() => mockSaisirNote(any(), any())).thenAnswer(
          (_) async => const Right(
            NoteEvaluation(
              id: 'n1',
              evaluationId: tEvaluationId,
              studentId: tStudentId,
              pointsObtenus: 15,
              statut: StatutNote.notee,
            ),
          ),
        );
      },
      build: buildBloc,
      seed: twoRowState,
      act: (bloc) => bloc.add(
        const NoteSaisie(
          evaluationId: tEvaluationId,
          studentId: tStudentId,
          statut: StatutNote.notee,
          pointsObtenus: 15,
        ),
      ),
      expect: () => [
        loadedState(
          rows: const [
            NoteEleveRow(note: tNote, saveStatus: RowSaveStatus.saving),
            NoteEleveRow(note: tNote2),
          ],
        ),
        loadedState(
          rows: const [
            NoteEleveRow(note: tNote1Saved15, saveStatus: RowSaveStatus.saved),
            NoteEleveRow(note: tNote2),
          ],
        ),
      ],
      verify: (bloc) {
        // s2 n'a jamais bougé (idle, note d'origine).
        expect(
          bloc.state.rowFor(tStudentId2),
          const NoteEleveRow(note: tNote2),
        );
      },
    );

    blocTest<SaisieNotesBloc, SaisieNotesState>(
      's1 en vol pendant que s2 sauve : la complétion tardive de s1 n\'écrase '
      'pas l\'état sauvé de s2',
      setUp: () {
        s1Completer = Completer<Either<Failure, NoteEvaluation>>();
        when(() => mockSaisirNote(any(), any())).thenAnswer((invocation) {
          final request =
              invocation.positionalArguments[1] as SaisirNoteRequest;
          // s1 reste « en vol » ; s2 se résout immédiatement.
          if (request.studentId == tStudentId) return s1Completer.future;
          return Future<Either<Failure, NoteEvaluation>>.value(
            const Right(
              NoteEvaluation(
                id: 'n2',
                evaluationId: tEvaluationId,
                studentId: tStudentId2,
                pointsObtenus: 12,
                statut: StatutNote.notee,
              ),
            ),
          );
        });
      },
      build: buildBloc,
      seed: twoRowState,
      act: (bloc) async {
        bloc.add(
          const NoteSaisie(
            evaluationId: tEvaluationId,
            studentId: tStudentId,
            statut: StatutNote.notee,
            pointsObtenus: 10,
          ),
        );
        // Laisse le handler de s1 émettre `saving` et se garer sur le completer.
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const NoteSaisie(
            evaluationId: tEvaluationId,
            studentId: tStudentId2,
            statut: StatutNote.notee,
            pointsObtenus: 12,
          ),
        );
        // Laisse s2 se sauver entièrement pendant que s1 est toujours en vol.
        await Future<void>.delayed(Duration.zero);
        // Puis la complétion TARDIVE de s1.
        s1Completer.complete(
          const Right(
            NoteEvaluation(
              id: 'n1',
              evaluationId: tEvaluationId,
              studentId: tStudentId,
              pointsObtenus: 10,
              statut: StatutNote.notee,
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        verify(() => mockSaisirNote(any(), any())).called(2);
        // État final : les DEUX lignes sont sauvées. Si le fold de s1 avait
        // réémis un snapshot périmé, s2 serait revenue à saving/idle.
        expect(
          bloc.state.rowFor(tStudentId),
          const NoteEleveRow(
            note: tNote1Saved10,
            saveStatus: RowSaveStatus.saved,
          ),
        );
        expect(
          bloc.state.rowFor(tStudentId2),
          const NoteEleveRow(
            note: tNote2Saved12,
            saveStatus: RowSaveStatus.saved,
          ),
        );
      },
    );
  });
}
