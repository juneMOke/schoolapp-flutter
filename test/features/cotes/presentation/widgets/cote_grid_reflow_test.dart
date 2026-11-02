import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_card.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_header_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../bloc/fake_cotes_repository.dart';

/// Les notes tiennent à côté des cours à 1280 ; à 620, elles défilent de côté.
const _fits = Size(1280, 900);
const _scrolls = Size(620, 900);

void main() {
  late FakeCotesRepository repository;
  late CoteSaisieBloc bloc;

  Future<void> pump(WidgetTester tester, {Size size = _fits}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository = FakeCotesRepository();
    bloc = CoteSaisieBloc(repository);
    final save = CoteSaveCubit(repository);
    bloc.add(const CoteSaisieOpened('c1'));
    await tester.runAsync(
      () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: save),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CoteBulletinCard(classroomName: '7e A'),
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
  }

  Finder field(int index) => find.byType(TextField).at(index);

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  Future<void> resize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    await tester.pump();
    await settle(tester);
  }

  /// La frappe du clavier réel, sans rouvrir la connexion comme le ferait
  /// `tester.enterText`.
  Future<void> typeOnKeyboard(WidgetTester tester, String text) async {
    tester.testTextInput.enterText(text);
    await tester.pump();
    await settle(tester);
  }

  testWidgets('la grille qui cesse de tenir garde la case, sa frappe et le '
      'clavier, sans rien écrire', (tester) async {
    await pump(tester);
    expect(find.byType(Scrollbar), findsNothing);
    await tester.tap(field(1));
    await tester.pump();
    await typeOnKeyboard(tester, '14');
    final node = tester.widget<TextField>(field(1)).focusNode!;

    await resize(tester, _scrolls);

    // La zone des notes défile désormais : la forme de l'arbre a changé.
    expect(find.byType(Scrollbar), findsOneWidget);
    expect(node.hasFocus, isTrue);
    expect(tester.widget<TextField>(field(1)).controller!.text, '14');
    expect(repository.saved, isEmpty);

    // Le clavier est toujours relié à la même case.
    await typeOnKeyboard(tester, '15');
    expect(tester.widget<TextField>(field(1)).controller!.text, '15');
    expect(repository.saved, isEmpty);

    await resize(tester, _fits);

    expect(node.hasFocus, isTrue);
    expect(tester.widget<TextField>(field(1)).controller!.text, '15');
    expect(repository.saved, isEmpty);
    final ready = bloc.state as CoteSaisieReady;
    expect(ready.cells.cell('e1', 'fr', 'P2')!.displayedValue, 15);
  });

  group('l\'en-tête des colonnes', () {
    Finder header(String text) => find.descendant(
      of: find.byType(CoteGridHeaderBand),
      matching: find.text(text),
    );

    ScrollPosition page(WidgetTester tester) => tester
        .state<ScrollableState>(
          find
              .ancestor(
                of: find.byType(CoteGrid),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;

    Future<void> scrollPageTo(WidgetTester tester, double offset) async {
      page(tester).jumpTo(offset);
      await tester.pump();
      await tester.pump();
    }

    testWidgets('reste en haut de l\'écran quand la page défile', (
      tester,
    ) async {
      await pump(tester, size: const Size(1280, 300));
      final gridTop = tester.getTopLeft(find.byType(CoteGrid)).dy;
      expect(tester.getTopLeft(header('COURS')).dy, greaterThan(gridTop - 1));

      await scrollPageTo(tester, gridTop + 60);

      // Le haut de la page visible, et non plus le haut de la grille, parti.
      expect(tester.getTopLeft(find.byType(CoteGrid)).dy, lessThan(0));
      final top = tester.getTopLeft(header('COURS')).dy;
      expect(top, inInclusiveRange(0, 12));
      expect(tester.getTopLeft(header('P1')).dy, inInclusiveRange(0, 12));

      // Revenu en haut, il reprend sa place.
      await scrollPageTo(tester, 0);
      expect(tester.getTopLeft(header('COURS')).dy, greaterThan(gridTop - 1));
    });

    testWidgets('s\'arrête au pied de la grille, sans le couvrir', (
      tester,
    ) async {
      await pump(tester, size: const Size(1280, 300));

      await scrollPageTo(tester, page(tester).maxScrollExtent);

      final grid = tester.getRect(find.byType(CoteGrid));
      final band = tester.getRect(find.byType(CoteGridHeaderBand));
      final maxima = tester.getTopLeft(find.text('MAXIMA')).dy;
      expect(band.bottom, lessThanOrEqualTo(maxima + 0.5));
      expect(band.top, greaterThanOrEqualTo(grid.top));
    });

    testWidgets('suit les notes qui défilent de côté', (tester) async {
      await pump(tester, size: _scrolls);
      final controller = tester
          .widget<SingleChildScrollView>(
            find.descendant(
              of: find.byType(CoteGrid),
              matching: find.byType(SingleChildScrollView),
            ),
          )
          .controller!;
      final before = tester.getTopLeft(header('P1')).dx;

      controller.jumpTo(40);
      await tester.pump();

      expect(tester.getTopLeft(header('P1')).dx, closeTo(before - 40, 0.5));
    });
  });

  group('replier au clavier', () {
    Future<void> alt(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await settle(tester);
    }

    bool focusedIn(WidgetTester tester, String branche) =>
        FocusManager.instance.primaryFocus?.debugLabel?.startsWith(
          'cote $branche',
        ) ??
        false;

    testWidgets('Alt+↑ replie la rubrique de la case, Alt+↓ déplie tout', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(TextField), findsNWidgets(5));
      await tester.tap(field(0));
      await tester.pump();
      await typeOnKeyboard(tester, '14');

      await alt(tester, LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // Les Langues repliées : restent les deux cases d'EPS, dont la première
      // a pris le focus ; la case quittée s'est écrite, comme à tout départ.
      expect(find.byType(TextField), findsNWidgets(2));
      expect(focusedIn(tester, 'Éducation physique'), isTrue);
      expect(repository.saved.single.$2, 14);

      await alt(tester, LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(5));
      expect(focusedIn(tester, 'Éducation physique'), isTrue);
    });

    testWidgets('la dernière rubrique repliée rend le focus à celle d\'avant', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(field(3));
      await tester.pump();

      await alt(tester, LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(3));
      expect(focusedIn(tester, 'Français'), isTrue);
    });

    testWidgets('sans case au focus, Alt+↑ ne fait rien', (tester) async {
      await pump(tester);

      await alt(tester, LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(5));
    });
  });
}
