import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/chapitre_children_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/programme_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_change_source.dart';

class _MockLoad extends Mock implements LoadChapitreUseCase {}

class _MockSave extends Mock implements SaveChapitreUseCase {}

class _MockAddNote extends Mock implements AddChapitreNoteUseCase {}

class _MockDeleteNote extends Mock implements DeleteChapitreNoteUseCase {}

class _MockOpen extends Mock implements OpenChapitreDocumentUseCase {}

void main() {
  final chapitre = Chapitre(
    id: 'ch-1',
    coursId: 'c-1',
    ordre: 0,
    titre: 'Fractions',
    objectifs: const [ChapitreObjectif(id: 'o-1', texte: 'Lire')],
    notes: [
      ChapitreNote(
        id: 'n-1',
        chapitreId: 'ch-1',
        texte: 'Séance',
        ecriteLe: DateTime.utc(2026, 10, 1),
      ),
    ],
  );
  late _MockLoad load;
  late _MockSave save;
  late _MockDeleteNote deleteNote;

  setUpAll(() => registerFallbackValue(chapitre));

  setUp(() {
    load = _MockLoad();
    save = _MockSave();
    deleteNote = _MockDeleteNote();
    when(() => load('ch-1')).thenAnswer(
      (_) async => Right(ChapitreDetail(chapitre: chapitre, numero: 1)),
    );
    when(() => deleteNote(any())).thenAnswer((_) async => const Right(unit));
  });

  ChapitreCubit build() => ChapitreCubit(
    chapitreId: 'ch-1',
    load: load,
    save: save,
    addNote: _MockAddNote(),
    deleteNote: deleteNote,
    openDocument: _MockOpen(),
    source: _silentSource(),
    undoWindow: const Duration(seconds: 5),
  );

  test('cocher un objectif enregistre la fiche entière, sans toucher au '
      'statut', () async {
    when(() => save(any())).thenAnswer(
      (inv) async => Right(inv.positionalArguments.single as Chapitre),
    );
    final cubit = build();
    await cubit.load();

    await cubit.toggleObjectif('o-1');

    final saved = verify(() => save(captureAny())).captured.single as Chapitre;
    expect(saved.objectifs.single.atteint, isTrue);
    expect(saved.statut, ChapitreStatut.planifie);
    await cubit.close();
  });

  test('une écriture locale en échec le dit', () async {
    when(
      () => save(any()),
    ).thenAnswer((_) async => const Left(StorageFailure()));
    final cubit = build();
    await cubit.load();

    await cubit.setStatut(ChapitreStatut.termine);

    expect(cubit.state.feedback?.kind, ChapitreFeedbackKind.writeFailed);
    await cubit.close();
  });

  // Sous `testWidgets` : `pump` avance l'horloge simulée, le délai
  // d'annulation se joue sans attendre cinq vraies secondes.
  testWidgets('une note supprimée se masque, puis part après le délai', (
    tester,
  ) async {
    final cubit = build();
    await cubit.load();

    cubit.requestNoteDeletion('n-1');
    expect(cubit.state.hiddenNotes, {'n-1'});
    expect(cubit.state.feedback?.noteId, 'n-1');
    verifyNever(() => deleteNote(any()));

    await tester.pump(const Duration(seconds: 5));
    verify(() => deleteNote('n-1')).called(1);
    await cubit.close();
  });

  testWidgets('annuler rend la note ; rien ne part', (tester) async {
    final cubit = build();
    await cubit.load();

    cubit.requestNoteDeletion('n-1');
    cubit.undoNoteDeletion('n-1');
    await tester.pump(const Duration(seconds: 6));

    expect(cubit.state.hiddenNotes, isEmpty);
    verifyNever(() => deleteNote(any()));
    await cubit.close();
  });

  test('quitter l\'écran n\'annule pas une suppression demandée', () async {
    final cubit = build();
    await cubit.load();
    cubit.requestNoteDeletion('n-1');

    await cubit.close();

    verify(() => deleteNote('n-1')).called(1);
  });
}

class _MockSource extends Mock implements ProgrammeChangeSource {}

/// Une source qui ne signale rien : les tests pilotent les relectures.
ProgrammeChangeSource _silentSource() {
  final source = _MockSource();
  when(
    () => source.watch(any(), onFlush: any(named: 'onFlush')),
  ).thenReturn(() {});
  return source;
}
