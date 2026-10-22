import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/saisir_note_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_state.dart';

class _GetNotes extends Mock implements GetNotesElevesUseCase {}

class _Saisir extends Mock implements SaisirNoteUseCase {}

/// Le commentaire d'une note (V179) depuis la grille : il repart avec la note
/// telle qu'elle est, et n'envoie `""` que pour retirer un commentaire existant.
void main() {
  late _GetNotes getNotes;
  late _Saisir saisir;

  NoteEleve eleve({StatutNote? statut, String? commentaire}) => NoteEleve(
    studentId: 's1',
    firstName: 'Jean',
    lastName: 'Dupont',
    pointsObtenus: statut == StatutNote.notee ? 14 : null,
    statut: statut,
    commentaire: commentaire,
  );

  Future<SaisieNotesBloc> loaded(NoteEleve note) async {
    when(() => getNotes('ev1')).thenAnswer((_) async => Right([note]));
    final bloc = SaisieNotesBloc(
      getNotesElevesUseCase: getNotes,
      saisirNoteUseCase: saisir,
    )..add(const NotesElevesLoaded(evaluationId: 'ev1', maxPoints: 20));
    await bloc.stream.firstWhere(
      (s) => s.gridStatus == SaisieNotesGridStatus.loaded,
    );
    return bloc;
  }

  Future<void> comment(SaisieNotesBloc bloc, String typed) async {
    bloc.add(
      NoteCommentaireSaisi(evaluationId: 'ev1', studentId: 's1', typed: typed),
    );
    await Future<void>.delayed(Duration.zero);
  }

  SaisirNoteRequest sent() =>
      verify(() => saisir('ev1', captureAny())).captured.single
          as SaisirNoteRequest;

  setUpAll(() {
    registerFallbackValue(
      SaisirNoteRequest.forStatut(
        studentId: 's1',
        statut: StatutNote.enAttente,
      ),
    );
  });

  setUp(() {
    getNotes = _GetNotes();
    saisir = _Saisir();
    when(() => saisir(any(), any())).thenAnswer((invocation) async {
      final request = invocation.positionalArguments[1] as SaisirNoteRequest;
      return Right(
        NoteEvaluation(
          id: 'n1',
          evaluationId: 'ev1',
          studentId: 's1',
          statut: request.statut,
          pointsObtenus: request.pointsObtenus,
          commentaire: request.commentaire,
        ),
      );
    });
  });

  test('le commentaire repart avec la note telle qu elle est', () async {
    final bloc = await loaded(eleve(statut: StatutNote.notee));

    await comment(bloc, ' Bon travail ');

    final request = sent();
    expect(request.statut, StatutNote.notee);
    expect(request.pointsObtenus, 14);
    expect(request.commentaire, 'Bon travail');
    expect(bloc.state.rowFor('s1')!.note.commentaire, 'Bon travail');
    await bloc.close();
  });

  test('vider un commentaire existant envoie ""', () async {
    final bloc = await loaded(
      eleve(statut: StatutNote.notee, commentaire: 'Bien'),
    );

    await comment(bloc, '');

    expect(sent().commentaire, '');
    await bloc.close();
  });

  test('un champ vide sans commentaire n envoie rien', () async {
    final bloc = await loaded(eleve(statut: StatutNote.notee));

    await comment(bloc, '   ');

    verifyNever(() => saisir(any(), any()));
    await bloc.close();
  });

  test('sans note saisie, pas de commentaire', () async {
    final bloc = await loaded(eleve());

    await comment(bloc, 'Bien');

    verifyNever(() => saisir(any(), any()));
    await bloc.close();
  });

  test(
    'au-delà de 1 000 caractères, la ligne est en erreur, rien ne part',
    () async {
      final bloc = await loaded(eleve(statut: StatutNote.absentJustifie));

      await comment(bloc, 'x' * 1001);

      verifyNever(() => saisir(any(), any()));
      expect(bloc.state.rowFor('s1')!.saveStatus, RowSaveStatus.error);
      await bloc.close();
    },
  );
}
