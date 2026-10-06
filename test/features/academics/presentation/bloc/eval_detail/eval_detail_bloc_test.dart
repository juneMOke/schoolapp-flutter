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
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';

class _MockGetSujet extends Mock implements GetEvaluationSujetUseCase {}

class _MockGetNotes extends Mock implements GetNotesElevesUseCase {}

NoteEleve _note(String id, StatutNote? statut) =>
    NoteEleve(studentId: id, firstName: 'A', lastName: 'B', statut: statut);

void main() {
  late _MockGetSujet getSujet;
  late _MockGetNotes getNotes;

  const sujet = EvaluationSujet(cadre: EvaluationCadre(dureeMinutes: 30));

  setUp(() {
    getSujet = _MockGetSujet();
    getNotes = _MockGetNotes();
  });

  EvalDetailBloc build() => EvalDetailBloc(
    getEvaluationSujetUseCase: getSujet,
    getNotesElevesUseCase: getNotes,
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
        progress: NotesProgress(saisies: 2, total: 4),
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
}
