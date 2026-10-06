import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/get_evaluation_sujet_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/resend_sujet_without_max_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/save_evaluation_sujet_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';

class _MockGetSujet extends Mock implements GetEvaluationSujetUseCase {}

class _MockGetNotes extends Mock implements GetNotesElevesUseCase {}

class _MockSaveSujet extends Mock implements SaveEvaluationSujetUseCase {}

class _MockResend extends Mock implements ResendSujetWithoutMaxUseCase {}

NoteEleve _note(String id, StatutNote? statut) =>
    NoteEleve(studentId: id, firstName: 'A', lastName: 'B', statut: statut);

void main() {
  late _MockGetSujet getSujet;
  late _MockGetNotes getNotes;
  late _MockSaveSujet saveSujet;
  late _MockResend resend;

  const sujet = EvaluationSujet(cadre: EvaluationCadre(dureeMinutes: 30));

  setUp(() {
    getSujet = _MockGetSujet();
    getNotes = _MockGetNotes();
    saveSujet = _MockSaveSujet();
    resend = _MockResend();
  });

  EvalDetailBloc build() => EvalDetailBloc(
    getEvaluationSujetUseCase: getSujet,
    getNotesElevesUseCase: getNotes,
    saveEvaluationSujetUseCase: saveSujet,
    resendSujetWithoutMaxUseCase: resend,
  );

  blocTest<EvalDetailBloc, EvalDetailState>(
    'prêt : sujet + avancement (absences comprises, attente exclue)',
    setUp: () {
      when(() => getSujet('ev-1')).thenAnswer((_) async => const Right(sujet));
      when(() => getNotes('ev-1')).thenAnswer(
        (_) async => Right([
          _note('a', StatutNote.notee),
          _note('b', StatutNote.absentJustifie),
          _note('c', StatutNote.enAttente),
          _note('d', null),
        ]),
      );
    },
    build: build,
    act: (bloc) => bloc.add(const EvalDetailRequested('ev-1')),
    expect: () => [
      const EvalDetailState(
        status: EvalDetailStatus.ready,
        sujet: sujet,
        progress: NotesProgress(saisies: 2, total: 4, notees: 1),
      ),
    ],
  );

  blocTest<EvalDetailBloc, EvalDetailState>(
    'un échec de lecture passe en erreur avec son Failure',
    setUp: () {
      when(
        () => getSujet('ev-1'),
      ).thenAnswer((_) async => const Left(StorageFailure()));
      when(() => getNotes('ev-1')).thenAnswer((_) async => const Right([]));
    },
    build: build,
    act: (bloc) => bloc.add(const EvalDetailRequested('ev-1')),
    expect: () => [
      const EvalDetailState(
        status: EvalDetailStatus.failure,
        failure: StorageFailure(),
      ),
    ],
  );

  test('NotesProgress.isComplete exige un effectif', () {
    expect(NotesProgress.empty.isComplete, isFalse);
    expect(const NotesProgress(saisies: 3, total: 3).isComplete, isTrue);
  });

  group('enregistrement du sujet', () {
    const q = SujetQuestion(id: 'q1', enonce: 'Q', points: 4);
    const saved = EvaluationSujet(questions: [q], envoi: SujetEnvoi.enAttente);

    void stubSave() => when(
      () => saveSujet(
        'ev-1',
        cadre: any(named: 'cadre'),
        questions: any(named: 'questions'),
        maxPoints: any(named: 'maxPoints'),
      ),
    ).thenAnswer((_) async => const Right(saved));

    setUpAll(() => registerFallbackValue(const EvaluationCadre()));

    blocTest<EvalDetailBloc, EvalDetailState>(
      'saving → saved (maximum ajusté) → idle',
      setUp: stubSave,
      build: build,
      seed: () => const EvalDetailState(status: EvalDetailStatus.ready),
      act: (bloc) => bloc.add(
        const EvalDetailSujetSaveRequested(
          evaluationId: 'ev-1',
          cadre: EvaluationCadre(),
          questions: [q],
          maxPoints: 4,
        ),
      ),
      expect: () => [
        const EvalDetailState(
          status: EvalDetailStatus.ready,
          sujetSave: SujetSaveStatus.saving,
        ),
        const EvalDetailState(
          status: EvalDetailStatus.ready,
          sujet: saved,
          sujetSave: SujetSaveStatus.saved,
          maxPoints: 4,
        ),
        const EvalDetailState(
          status: EvalDetailStatus.ready,
          sujet: saved,
          maxPoints: 4,
        ),
      ],
    );

    blocTest<EvalDetailBloc, EvalDetailState>(
      'une note posée fige le maximum : il ne part pas',
      setUp: stubSave,
      build: build,
      seed: () => const EvalDetailState(
        status: EvalDetailStatus.ready,
        progress: NotesProgress(saisies: 1, total: 2, notees: 1),
      ),
      act: (bloc) => bloc.add(
        const EvalDetailSujetSaveRequested(
          evaluationId: 'ev-1',
          cadre: EvaluationCadre(),
          questions: [q],
          maxPoints: 4,
        ),
      ),
      verify: (_) => verify(
        () => saveSujet(
          'ev-1',
          cadre: any(named: 'cadre'),
          questions: any(named: 'questions'),
          maxPoints: null,
        ),
      ).called(1),
    );

    blocTest<EvalDetailBloc, EvalDetailState>(
      'un échec garde le brouillon : failed puis idle',
      setUp: () => when(
        () => saveSujet(
          'ev-1',
          cadre: any(named: 'cadre'),
          questions: any(named: 'questions'),
          maxPoints: any(named: 'maxPoints'),
        ),
      ).thenAnswer((_) async => const Left(StorageFailure())),
      build: build,
      seed: () => const EvalDetailState(status: EvalDetailStatus.ready),
      act: (bloc) => bloc.add(
        const EvalDetailSujetSaveRequested(
          evaluationId: 'ev-1',
          cadre: EvaluationCadre(),
          questions: [q],
        ),
      ),
      expect: () => [
        const EvalDetailState(
          status: EvalDetailStatus.ready,
          sujetSave: SujetSaveStatus.saving,
        ),
        const EvalDetailState(
          status: EvalDetailStatus.ready,
          sujetSave: SujetSaveStatus.failed,
        ),
        const EvalDetailState(status: EvalDetailStatus.ready),
      ],
    );
  });

  blocTest<EvalDetailBloc, EvalDetailState>(
    'renvoi sans maximum : le sujet repart en attente',
    setUp: () => when(() => resend('ev-1')).thenAnswer(
      (_) async => const Right(EvaluationSujet(envoi: SujetEnvoi.enAttente)),
    ),
    build: build,
    seed: () => const EvalDetailState(
      status: EvalDetailStatus.ready,
      sujet: EvaluationSujet(
        envoi: SujetEnvoi.refuse,
        rejectionCode: 'MAX_LOCKED',
      ),
    ),
    act: (bloc) => bloc.add(const EvalDetailSujetResendRequested('ev-1')),
    skip: 1,
    expect: () => [
      const EvalDetailState(
        status: EvalDetailStatus.ready,
        sujet: EvaluationSujet(envoi: SujetEnvoi.enAttente),
        sujetSave: SujetSaveStatus.resent,
      ),
      const EvalDetailState(
        status: EvalDetailStatus.ready,
        sujet: EvaluationSujet(envoi: SujetEnvoi.enAttente),
      ),
    ],
  );
}
