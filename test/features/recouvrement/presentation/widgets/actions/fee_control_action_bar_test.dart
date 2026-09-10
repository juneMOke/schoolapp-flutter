import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/actions/fee_control_action_bar.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/actions/fee_control_marked_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre d'actions et l'encart des renvois — deux strates **conditionnelles**
/// qui n'occupent aucune place tant qu'elles sont vides.
///
/// Harnais sous `AppTheme.light` : les boutons y sont inline dans un `Wrap`, et
/// le thème leur donne une largeur minimale infinie. Sans le vrai thème, un
/// oubli de `minimumSize` passerait inaperçu jusqu'au terrain.
void main() {
  late FeeControlSelectionCubit cubit;
  late int callLists;
  late int marks;

  setUp(() {
    cubit = FeeControlSelectionCubit();
    callLists = 0;
    marks = 0;
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1180, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<FeeControlSelectionCubit>.value(
          value: cubit,
          child: Scaffold(
            body: Column(
              children: [
                FeeControlActionBar(
                  onCallList: () => callLists++,
                  onMark: () => marks++,
                ),
                const FeeControlMarkedCard(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans sélection, la barre n\'occupe aucune place', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Liste d\'appel'), findsNothing);
    expect(find.text('Marquer à renvoyer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une sélection fait apparaître la barre et compte les élèves', (
    tester,
  ) async {
    await pump(tester);

    cubit.toggle('s1');
    cubit.toggle('s2');
    await tester.pumpAndSettle();

    expect(find.text('2 élèves sélectionnés'), findsOneWidget);
    expect(find.text('Liste d\'appel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('« Désélectionner » sort sans conséquence', (tester) async {
    await pump(tester);
    cubit.toggle('s1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Désélectionner'));
    await tester.pumpAndSettle();

    expect(cubit.state.selected, isEmpty);
    // Rien n'a été marqué au passage : sortir n'est pas décider.
    expect(cubit.state.marked, isEmpty);
  });

  testWidgets('marquer relaie le geste à la page', (tester) async {
    await pump(tester);
    cubit.toggle('s1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marquer à renvoyer'));
    await tester.pumpAndSettle();

    expect(marks, 1);
    expect(callLists, 0);
  });

  testWidgets('l\'encart de renvois dit que rien n\'est notifié', (
    tester,
  ) async {
    await pump(tester);

    cubit.mark(['s1', 's2', 's3']);
    await tester.pumpAndSettle();

    expect(find.text('3 élèves marqués « à renvoyer »'), findsOneWidget);
    expect(
      find.textContaining('rien n\'est notifié aux familles'),
      findsOneWidget,
    );
    // Ce qui n'existe pas : aucun bouton n'applique quoi que ce soit.
    expect(find.textContaining('Appliquer'), findsNothing);
  });

  testWidgets('marquer en lot VIDE la sélection — le geste est consommé', (
    tester,
  ) async {
    await pump(tester);
    cubit.toggle('s1');
    cubit.toggle('s2');
    await tester.pumpAndSettle();

    cubit.mark(cubit.state.selected);
    await tester.pumpAndSettle();

    expect(cubit.state.marked, {'s1', 's2'});
    expect(cubit.state.selected, isEmpty);
    expect(find.text('2 élèves sélectionnés'), findsNothing);
  });

  testWidgets('vider la liste des renvois la fait disparaître', (tester) async {
    await pump(tester);
    cubit.mark(['s1']);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vider la liste des renvois'));
    await tester.pumpAndSettle();

    expect(cubit.state.marked, isEmpty);
    expect(find.textContaining('marqué'), findsNothing);
  });
}
