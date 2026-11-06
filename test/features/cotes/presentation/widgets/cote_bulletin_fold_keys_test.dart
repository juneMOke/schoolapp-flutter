import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_card.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../bloc/fake_cotes_repository.dart';

/// Alt+↓ déplie toute la grille, Alt+←/→ changent d'élève — sauf quand le
/// focus est dans un champ ou une liste hors de la grille, qui ont l'usage de
/// ces touches (Option+← : mot précédent sur macOS).
void main() {
  late FakeCotesRepository repository;
  late CoteSaisieBloc bloc;
  late FocusNode search;
  late FocusNode select;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    search = FocusNode(debugLabel: 'recherche');
    select = FocusNode(debugLabel: 'liste');
    addTearDown(search.dispose);
    addTearDown(select.dispose);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(focusNode: search),
                  Focus(
                    focusNode: select,
                    child: EteeloSelectInput<String>(
                      label: 'Élève',
                      items: const [EteeloSelectItem(value: 'e1', label: 'A')],
                      value: null,
                      onChanged: (_) {},
                    ),
                  ),
                  const CoteBulletinCard(classroomName: '7e A'),
                ],
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
  }

  Finder cells() => find.descendant(
    of: find.byType(CoteGrid),
    matching: find.byType(TextField),
  );

  Future<void> alt(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  /// Les Langues repliées depuis leur première case.
  Future<void> collapseLanguages(WidgetTester tester) async {
    await tester.tap(cells().first);
    await tester.pump();
    await alt(tester, LogicalKeyboardKey.arrowUp);
    expect(cells(), findsNWidgets(2));
  }

  testWidgets('dans un champ hors de la grille, Alt+↓ lui reste', (
    tester,
  ) async {
    await pump(tester);
    await collapseLanguages(tester);

    search.requestFocus();
    await tester.pump();
    await alt(tester, LogicalKeyboardKey.arrowDown);

    expect(cells(), findsNWidgets(2));
  });

  testWidgets('sur une liste hors de la grille, Alt+↓ lui reste', (
    tester,
  ) async {
    await pump(tester);
    await collapseLanguages(tester);

    // Le focus de la liste elle-même, sous celui qui l'enveloppe.
    select.children.first.requestFocus();
    await tester.pump();
    await alt(tester, LogicalKeyboardKey.arrowDown);

    expect(cells(), findsNWidgets(2));
  });

  group('Alt+← / Alt+→ : l\'élève voisin', () {
    String? selected() => (bloc.state as CoteSaisieReady).currentId;

    testWidgets('dans un champ hors de la grille, la touche lui reste', (
      tester,
    ) async {
      await pump(tester);
      final before = selected();

      search.requestFocus();
      await tester.pump();
      await alt(tester, LogicalKeyboardKey.arrowRight);

      expect(selected(), before);
    });

    testWidgets('depuis une case de la grille, Alt+→ passe à l\'élève '
        'suivant', (tester) async {
      await pump(tester);
      final before = selected();

      await tester.tap(cells().first);
      await tester.pump();
      await alt(tester, LogicalKeyboardKey.arrowRight);

      expect(selected(), isNot(before));
    });

    testWidgets('sans focus, Alt+→ passe encore à l\'élève suivant', (
      tester,
    ) async {
      await pump(tester);
      final before = selected();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await alt(tester, LogicalKeyboardKey.arrowRight);

      expect(selected(), isNot(before));
    });
  });

  testWidgets('sans focus, Alt+↓ déplie encore tout', (tester) async {
    await pump(tester);
    await collapseLanguages(tester);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await alt(tester, LogicalKeyboardKey.arrowDown);

    expect(cells(), findsNWidgets(5));
  });
}
