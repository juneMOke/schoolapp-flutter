import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../bloc/fake_cotes_repository.dart';

const _longName = 'Éducation civique et morale, vie courante et citoyenneté';

const _classe = CoteClasse(
  classroomId: 'c1',
  decoupage: Decoupage.semestre,
  periodes: [
    CotePeriode(
      id: 'S1',
      ordre: 1,
      libelle: 'Semestre 1',
      courant: true,
      locked: false,
      sousPeriodes: [
        CoteSousPeriode(id: 'P1', ordre: 1, locked: false),
        CoteSousPeriode(id: 'P2', ordre: 2, locked: false),
      ],
    ),
  ],
  rubriques: [
    CoteRubrique(
      id: 'd1',
      label: 'Domaine des langues',
      sousRubriques: [
        CoteRubrique(
          id: 'b1',
          label: 'Français',
          cours: [
            CoteCours(
              coursId: 'a',
              branche: _longName,
              maxJournalier: 10,
              maxExamen: 20,
            ),
            CoteCours(
              coursId: 'b',
              branche: 'Vocabulaire',
              maxJournalier: 20,
              maxExamen: 40,
            ),
          ],
        ),
      ],
    ),
  ],
  eleves: [CoteEleve(studentId: 's1', lastName: 'Mbaya', firstName: 'Ada')],
);

Future<CoteSaisieBloc> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bloc = CoteSaisieBloc(
    FakeCotesRepository(
      classe: _classe,
      cells: const [
        CoteCell(
          key: CoteCellKey(
            studentId: 's1',
            coursId: 'a',
            colonneId: 'P1',
            examen: false,
          ),
          serverCote: 4,
        ),
        CoteCell(
          key: CoteCellKey(
            studentId: 's1',
            coursId: 'b',
            colonneId: 'P1',
            examen: false,
          ),
          serverCote: 15.5,
        ),
      ],
    ),
  );
  bloc.add(
    const CoteSaisieOpened(
      'c1',
      scope: CoteScope(portee: CotePortee.groupe, cibleId: 'S1'),
    ),
  );
  await tester.runAsync(
    () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
  );
  var collapsed = <String>{};
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
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
            child: StatefulBuilder(
              builder: (context, setState) => CoteGrid(
                enterMove: CoteMove.down,
                collapsed: collapsed,
                onToggleRubrique: (id) => setState(() {
                  collapsed = collapsed.contains(id)
                      ? (collapsed.toSet()..remove(id))
                      : {...collapsed, id};
                }),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  addTearDown(() => tester.runAsync(bloc.close));
  return bloc;
}

void main() {
  testWidgets('la grille suit le bulletin : maxima, titres, sous-total', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('MAX PÉR.'), findsOneWidget);
    expect(find.text('MAX EX.'), findsOneWidget);
    expect(find.text('DOMAINE DES LANGUES'), findsOneWidget);
    expect(find.text('FRANÇAIS'), findsOneWidget);
    expect(find.text('Sous-total'), findsOneWidget);
    // Le nom long s'affiche, l'ancienne ligne de barème a disparu.
    expect(find.text(_longName), findsOneWidget);
    expect(find.textContaining('sur 10'), findsNothing);
    // Σ des maxima : 10 + 20 par période, 20 + 40 à l'examen.
    expect(find.text('30'), findsWidgets);
    expect(find.text('60'), findsWidgets);
    // Σ de P1 sur la branche.
    expect(find.text('19,5'), findsWidgets);

    final title = tester.getCenter(find.text('DOMAINE DES LANGUES'));
    final grid = tester.getCenter(find.byType(CoteGrid));
    expect((title.dx - grid.dx).abs(), lessThan(40));
  });

  testWidgets('les points se colorent selon la moitié du maximum', (
    tester,
  ) async {
    await _pump(tester);
    Color? ink(String value) => tester
        .widget<TextField>(
          find.ancestor(of: find.text(value), matching: find.byType(TextField)),
        )
        .style
        ?.color;
    expect(ink('4'), AppColors.error); // 4/10
    expect(ink('15,5'), AppColors.vertSavane); // 15,5/20
  });

  testWidgets('une note sous la moitié se souligne : pas la couleur seule', (
    tester,
  ) async {
    await _pump(tester);
    TextDecoration? mark(String value) => tester
        .widget<TextField>(
          find.ancestor(of: find.text(value), matching: find.byType(TextField)),
        )
        .style
        ?.decoration;
    expect(mark('4'), TextDecoration.underline); // 4/10
    expect(mark('15,5'), TextDecoration.none); // 15,5/20
  });

  testWidgets('une branche se replie : il reste son titre et sa somme', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text(_longName), findsOneWidget);

    await tester.tap(find.text('FRANÇAIS'));
    await tester.pump();
    expect(find.text(_longName), findsNothing);
    expect(find.text('Sous-total'), findsOneWidget);
    expect(find.text('19,5'), findsWidgets);

    await tester.tap(find.text('FRANÇAIS'));
    await tester.pump();
    expect(find.text(_longName), findsOneWidget);
  });

  testWidgets('le lecteur d\'écran replie une rubrique', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    expect(find.text(_longName), findsOneWidget);

    // excludeSemantics retirait l'action de l'InkWell : le bouton annoncé
    // était inerte.
    final node = tester.getSemantics(find.bySemanticsLabel('Français'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Français'));
    await tester.pump();
    expect(find.text(_longName), findsNothing);
    handle.dispose();
  });

  testWidgets('le survol d\'un domaine prend le voile de survol', (
    tester,
  ) async {
    await _pump(tester);
    final ink = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('DOMAINE DES LANGUES'),
        matching: find.byType(InkWell),
      ),
    );
    expect(ink.hoverColor, AppColors.stateHoverOnDark);
  });

  testWidgets('un domaine replié cache ses branches', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('DOMAINE DES LANGUES'));
    await tester.pump();
    expect(find.text('FRANÇAIS'), findsNothing);
    expect(find.text('Sous-total'), findsOneWidget);
  });

  testWidgets('replier une frappe en cours l\'enregistre', (tester) async {
    final bloc = await _pump(tester);
    final field = find.byType(TextField).at(1);
    await tester.tap(field);
    await tester.pump();
    tester.testTextInput.enterText('9');
    await tester.pump();

    await tester.tap(find.text('FRANÇAIS'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    final state = bloc.state as CoteSaisieReady;
    final cell = state.cells.cell('s1', 'a', 'P2');
    expect(cell?.displayedValue, 9);
    expect(cell?.hasDraft, isTrue);
  });
}
