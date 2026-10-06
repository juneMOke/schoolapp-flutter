import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_state.dart';
import 'package:school_app_flutter/features/course_programme/presentation/pages/programme_page.dart';

import '../programme_test_host.dart';

class _MockProgrammeCubit extends MockCubit<ProgrammeState>
    implements ProgrammeCubit {}

void main() {
  late _MockProgrammeCubit cubit;

  void stub(ProgrammeState state) {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, Stream<ProgrammeState>.value(state), initialState: state);
  }

  final programme = const Programme(
    coursId: 'c-1',
    evaluationsCount: 5,
    chapitres: [
      ProgrammeChapitre(
        chapitre: Chapitre(
          id: 'a',
          coursId: 'c-1',
          ordre: 0,
          titre: 'Nombres entiers',
          statut: ChapitreStatut.termine,
          seances: 5,
        ),
        evaluationsCount: 2,
        notesCount: 1,
      ),
      ProgrammeChapitre(
        chapitre: Chapitre(
          id: 'b',
          coursId: 'c-1',
          ordre: 1,
          titre: 'Fractions',
          statut: ChapitreStatut.enCours,
        ),
      ),
    ],
  );

  setUp(() => cubit = _MockProgrammeCubit());

  Widget page({List<String> permissions = kProgrammeTeacher}) => programmeHost(
    BlocProvider<ProgrammeCubit>.value(
      value: cubit,
      child: ProgrammePage(
        cours: kMathsCours,
        onBack: () {},
        onOpenChapitre: (_) {},
      ),
    ),
    permissions: permissions,
  );

  testWidgets('en-tête, avancement et rangées numérotées', (tester) async {
    stub(ProgrammeState(status: ProgrammeStatus.ready, programme: programme));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.text('Mathématiques'), findsOneWidget);
    expect(find.text('2 chapitres'), findsOneWidget);
    expect(find.text('50 %'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('Nombres entiers'), findsOneWidget);
    expect(find.text('1 note'), findsOneWidget);
    // Le premier ne monte pas, le dernier ne descend pas.
    expect(find.byTooltip('Monter'), findsOneWidget);
    expect(find.byTooltip('Descendre'), findsOneWidget);
  });

  testWidgets('la direction lit sans aucune action', (tester) async {
    stub(ProgrammeState(status: ProgrammeStatus.ready, programme: programme));
    await tester.pumpWidget(page(permissions: kProgrammeReader));
    await tester.pumpAndSettle();

    expect(find.text('Fractions'), findsOneWidget);
    expect(find.byTooltip('Monter'), findsNothing);
    expect(find.byTooltip('Supprimer'), findsNothing);
  });

  testWidgets('supprimer demande confirmation, puis supprime', (tester) async {
    stub(ProgrammeState(status: ProgrammeStatus.ready, programme: programme));
    when(() => cubit.delete('b')).thenAnswer((_) async {});
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Supprimer').last);
    await tester.pumpAndSettle();
    expect(find.text('Supprimer le chapitre ?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer').last);
    await tester.pumpAndSettle();
    verify(() => cubit.delete('b')).called(1);
  });

  testWidgets('programme vide : l\'issue est de créer un chapitre', (
    tester,
  ) async {
    stub(
      const ProgrammeState(
        status: ProgrammeStatus.ready,
        programme: Programme(coursId: 'c-1', chapitres: []),
      ),
    );
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.text('Programme vide'), findsOneWidget);
    expect(find.text('Créer un chapitre'), findsOneWidget);
  });

  testWidgets('sur un téléphone (360 dp), rien ne déborde ; Modifier et '
      'Supprimer passent dans « ⋮ »', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    stub(ProgrammeState(status: ProgrammeStatus.ready, programme: programme));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Plus d\'actions'), findsNWidgets(2));
    expect(find.byTooltip('Supprimer'), findsNothing);
  });
}
