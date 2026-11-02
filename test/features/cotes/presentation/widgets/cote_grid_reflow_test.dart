import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../bloc/fake_cotes_repository.dart';

/// Les notes tiennent à côté des cours à 1280 ; à 620, elles défilent de côté.
const _fits = Size(1280, 900);
const _scrolls = Size(620, 900);

void main() {
  late FakeCotesRepository repository;
  late CoteSaisieBloc bloc;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = _fits;
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
}
