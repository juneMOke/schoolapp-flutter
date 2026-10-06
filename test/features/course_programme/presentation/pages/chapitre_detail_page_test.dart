import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/pages/chapitre_detail_page.dart';

import '../programme_test_host.dart';

class _MockChapitreCubit extends MockCubit<ChapitreState>
    implements ChapitreCubit {}

void main() {
  late _MockChapitreCubit cubit;

  final detail = ChapitreDetail(
    numero: 3,
    chapitre: Chapitre(
      id: 'ch-1',
      coursId: 'c-1',
      ordre: 2,
      titre: 'Fractions et décimaux',
      statut: ChapitreStatut.enCours,
      sousPeriodeId: 'sp-1',
      objectifs: const [
        ChapitreObjectif(id: 'o-1', texte: 'Comparer', atteint: true),
        ChapitreObjectif(id: 'o-2', texte: 'Ranger'),
      ],
      strategies: const ['Travail en groupe'],
      notes: [
        ChapitreNote(
          id: 'n-1',
          chapitreId: 'ch-1',
          texte: 'Reprendre les prérequis',
          ecriteLe: DateTime.utc(2026, 10, 2),
        ),
      ],
    ),
    evaluations: [
      ChapitreEvaluationLink(
        id: 'ev-1',
        type: TypeEvaluation.interro,
        date: DateTime.utc(2026, 10, 3),
        maxPoints: 20,
      ),
    ],
  );

  void stub(ChapitreState state) {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, Stream<ChapitreState>.value(state), initialState: state);
  }

  setUp(() => cubit = _MockChapitreCubit());

  Widget page({List<String> permissions = kProgrammeTeacher}) => programmeHost(
    BlocProvider<ChapitreCubit>.value(
      value: cubit,
      child: ChapitreDetailPage(
        cours: kMathsCours,
        titre: 'Fractions et décimaux',
        sousPeriodes: const [SousPeriodeOption(id: 'sp-1', ordre: 1)],
        onBack: () {},
        onOpenEvaluations: () {},
      ),
    ),
    permissions: permissions,
  );

  Future<void> pump(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  testWidgets('en-tête, sections et évaluations liées', (tester) async {
    stub(ChapitreState(status: ChapitreStatus.ready, detail: detail));
    await pump(tester, page());

    expect(find.text('03'), findsOneWidget);
    expect(find.text('Période 1'), findsOneWidget);
    expect(find.text('1/2 objectifs atteints'), findsOneWidget);
    expect(find.text('Travail en groupe'), findsOneWidget);
    expect(find.text('Reprendre les prérequis'), findsOneWidget);
    expect(find.text('Interrogation'), findsOneWidget);
    expect(find.text('Aucune ressource attachée.'), findsOneWidget);
  });

  testWidgets('cocher un objectif passe par le cubit', (tester) async {
    stub(ChapitreState(status: ChapitreStatus.ready, detail: detail));
    when(() => cubit.toggleObjectif('o-2')).thenAnswer((_) async {});
    await pump(tester, page());

    await tester.tap(find.text('Ranger'));
    verify(() => cubit.toggleObjectif('o-2')).called(1);
  });

  testWidgets('la direction lit : ni note à ajouter, ni case à cocher', (
    tester,
  ) async {
    stub(ChapitreState(status: ChapitreStatus.ready, detail: detail));
    await pump(tester, page(permissions: kProgrammeReader));

    expect(find.text('Ajouter une note'), findsNothing);
    expect(find.text('Modifier'), findsNothing);
    await tester.tap(find.text('Ranger'));
    verifyNever(() => cubit.toggleObjectif(any()));
  });

  testWidgets('une note masquée n\'est plus montrée', (tester) async {
    stub(
      ChapitreState(
        status: ChapitreStatus.ready,
        detail: detail,
        hiddenNotes: const {'n-1'},
      ),
    );
    await pump(tester, page());
    expect(find.text('Reprendre les prérequis'), findsNothing);
  });
}
