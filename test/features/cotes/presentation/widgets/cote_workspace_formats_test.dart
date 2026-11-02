import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_note_cell.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_panel.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_picker.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/selection/cote_scope_bar.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/workspace/cote_workspace.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../bloc/fake_cotes_repository.dart';

Future<(CoteSaisieBloc, CoteSaveCubit)> _pump(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  CoteScope? scope,
  List<CoteCell> cells = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = FakeCotesRepository(cells: cells);
  final bloc = CoteSaisieBloc(repository);
  final save = CoteSaveCubit(repository);
  bloc.add(CoteSaisieOpened('c1', scope: scope));
  await tester.runAsync(
    () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
  );
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider.value(value: save),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  BlocBuilder<CoteSaisieBloc, CoteSaisieState>(
                    builder: (context, state) {
                      if (state is! CoteSaisieReady) {
                        return const SizedBox.shrink();
                      }
                      return CoteScopeBar(
                        classe: state.classe,
                        scope: state.scope,
                        year: state.year,
                        onChanged: (_) {},
                      );
                    },
                  ),
                  const CoteWorkspace(classroomName: '7e A'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  addTearDown(() async {
    await tester.runAsync(() async {
      await save.close();
      await bloc.close();
    });
  });
  return (bloc, save);
}

const _formats = {
  'téléphone': Size(360, 740),
  '7 pouces portrait': Size(600, 960),
  '7 pouces paysage': Size(960, 600),
  '10 pouces portrait': Size(800, 1280),
  '10 pouces paysage': Size(1280, 800),
  'poste 1440': Size(1440, 900),
  'poste 1920': Size(1920, 1080),
};

void main() {
  for (final entry in _formats.entries) {
    for (final portee in CotePortee.values) {
      testWidgets('${entry.key}, portée ${portee.name} : aucun débordement', (
        tester,
      ) async {
        await _pump(
          tester,
          size: entry.value,
          scope: CoteScope(
            portee: portee,
            cibleId: switch (portee) {
              CotePortee.groupe => 'S1',
              CotePortee.colonne => 'P1',
              CotePortee.annee => null,
            },
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Mbaya'), findsWidgets);
      });
    }
  }

  testWidgets('texte ×1,3 sur téléphone : aucun débordement', (tester) async {
    await _pump(tester, size: const Size(360, 740), textScale: 1.3);

    expect(tester.takeException(), isNull);
  });

  testWidgets('texte ×1,3 en année, 10 pouces : aucun débordement', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1280, 800),
      textScale: 1.3,
      scope: const CoteScope(portee: CotePortee.annee),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('la liste s\'affiche quand la grille tient à côté', (
    tester,
  ) async {
    await _pump(tester, size: const Size(1440, 900));

    expect(find.byType(CoteStudentPanel), findsOneWidget);
    expect(find.byType(CoteStudentPicker), findsNothing);
  });

  testWidgets('sinon, un sélecteur prend sa place', (tester) async {
    await _pump(tester, size: const Size(800, 1280));

    expect(find.byType(CoteStudentPanel), findsNothing);
    expect(find.byType(CoteStudentPicker), findsOneWidget);
  });

  testWidgets('les cibles de saisie font au moins 48 dp', (tester) async {
    await _pump(tester, size: const Size(1280, 800));

    final cell = tester.getSize(find.byType(CoteNoteCell).first);
    expect(cell.height, greaterThanOrEqualTo(48));
  });

  testWidgets('une colonne verrouillée n\'a pas de champ', (tester) async {
    await _pump(
      tester,
      size: const Size(1440, 900),
      scope: const CoteScope(portee: CotePortee.groupe, cibleId: 'S2'),
    );

    // P3 et l'examen S2 sont clôturés, P4 reste ouverte (cours avec examen),
    // l'examen n'a pas de cellule sur l'EPS.
    expect(find.byType(CoteNoteCell), findsNWidgets(2));
  });

  testWidgets('une frappe met le total à jour sans reconstruire la grille', (
    tester,
  ) async {
    final (bloc, _) = await _pump(tester, size: const Size(1440, 900));

    await tester.enterText(find.byType(TextField).at(1), '18');
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.textContaining('18'), findsWidgets);
    expect((bloc.state as CoteSaisieReady).current.total, 1800);
  });

  testWidgets('une cote refusée s\'abandonne depuis le pied', (tester) async {
    await _pump(
      tester,
      size: const Size(1440, 900),
      cells: [
        CoteCell(
          key: demoKey('P1'),
          hasDraft: true,
          draftValue: 15,
          syncState: SyncState.syncError,
          rejectionReason: 'PERIODE_CLOSE',
        ),
      ],
    );

    expect(find.text('Abandonner'), findsOneWidget);
    expect(find.textContaining('colonne clôturée'), findsWidgets);
  });

  testWidgets('animations réduites : tourner l\'écran ne lève rien', (
    tester,
  ) async {
    await _pump(tester, size: const Size(1280, 800));

    tester.view.physicalSize = const Size(800, 1280);
    await tester.pump();
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
