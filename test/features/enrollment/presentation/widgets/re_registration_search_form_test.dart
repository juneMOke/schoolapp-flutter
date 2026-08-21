import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/re_registration_search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _options = [
  ReRegistrationAcademicOption(
    schoolLevelGroupId: 'g1',
    schoolLevelId: 'l1',
    label: 'Primaire - 1ère',
  ),
  ReRegistrationAcademicOption(
    schoolLevelGroupId: 'g2',
    schoolLevelId: 'l3',
    label: 'Secondaire - 6ème',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required void Function(EnrollmentSearchCommand) dispatch,
  List<ReRegistrationAcademicOption> options = _options,
  bool isLoading = false,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: ReRegistrationSearchForm(
          options: options,
          isLoading: isLoading,
          dispatch: dispatch,
        ),
      ),
    ),
  );
  // En chargement, le bouton d'action porte un indicateur qui tourne sans fin :
  // `pumpAndSettle` ne rendrait jamais la main.
  if (isLoading) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sans référentiel, la carte ouvre sur l\'identité', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {}, options: const []);

    // « Par classe » n'offrirait que deux listes grisées : ce serait un
    // cul-de-sac, alors que la recherche par nom reste praticable.
    expect(_shownMode(tester), SearchMode.identity);
    expect(find.byType(EteeloTextInput), findsNWidgets(3));
  });

  testWidgets('le référentiel arrivé après coup ramène au mode classe', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {}, options: const []);
    expect(_shownMode(tester), SearchMode.identity);

    await _pump(tester, dispatch: (_) {});
    expect(_shownMode(tester), SearchMode.level);
  });

  testWidgets('mais jamais après que l\'utilisateur a engagé quelque chose', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {}, options: const []);
    await tester.enterText(find.byType(TextField).first, 'Kabongo');
    await tester.pumpAndSettle();

    await _pump(tester, dispatch: (_) {});

    expect(
      _shownMode(tester),
      SearchMode.identity,
      reason: 'une saisie en cours ne se fait pas balayer par le référentiel',
    );
    expect(find.text('Kabongo'), findsOneWidget);
  });

  testWidgets('la bascule est grisée pendant une recherche', (tester) async {
    await _pump(tester, dispatch: (_) {}, isLoading: true);

    final tabs = tester.widget<SegmentedTabFilter<SearchMode>>(
      find.byType(SegmentedTabFilter<SearchMode>),
    );
    expect(tabs.enabled, isFalse);

    await tester.tap(find.text('Par identité'), warnIfMissed: false);
    await tester.pump();
    expect(
      _shownMode(tester),
      SearchMode.level,
      reason: 'basculer changerait les champs sous une requête en vol',
    );
  });

  testWidgets(
    'la carte s\'ouvre sur « Par classe » : cascade, pas d\'identité',
    (tester) async {
      await _pump(tester, dispatch: (_) {});

      expect(tester.takeException(), isNull);
      expect(find.byType(BiToneSectionCard), findsOneWidget);
      // Cycle + Niveau, plus le seul champ du mode : l'affinage facultatif.
      expect(find.byType(EteeloSelectInput<String>), findsNWidgets(2));
      expect(find.byType(EteeloTextInput), findsOneWidget);
      expect(find.text('Affiner par nom (facultatif)'), findsOneWidget);
    },
  );

  testWidgets('la bascule est annoncée, et son aide nomme l\'autre mode', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {});

    expect(find.text('RECHERCHER PAR'), findsOneWidget);
    expect(find.text('Par classe'), findsOneWidget);
    expect(find.text('Par identité'), findsOneWidget);
    // L'aide du mode actif dit par où sortir : c'est ce qui rend la bascule
    // trouvable pour qui est entré par la mauvaise porte.
    expect(
      find.textContaining('basculez sur « Par identité »'),
      findsOneWidget,
    );

    await _switchToIdentity(tester);
    expect(find.textContaining('basculez sur « Par classe »'), findsOneWidget);
  });

  testWidgets('basculer sur « Par identité » révèle les trois champs', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {});
    await _switchToIdentity(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(EteeloTextInput), findsNWidgets(3));
    expect(find.byType(EteeloSelectInput<String>), findsNothing);
  });

  testWidgets('identité : dispatch AcademicInfoSearchCommand sans niveau', (
    tester,
  ) async {
    EnrollmentSearchCommand? captured;
    await _pump(tester, dispatch: (cmd) => captured = cmd);
    await _switchToIdentity(tester);

    await _enterNames(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    final command = captured! as AcademicInfoSearchCommand;
    expect(command.firstName, 'Daniel');
    expect(command.lastName, 'Kabongo');
    expect(command.surname, 'Mwamba');
    expect(command.schoolLevelGroupId, isEmpty);
    expect(command.schoolLevelId, isEmpty);
  });

  testWidgets('classe : le niveau part seul, les noms de l\'autre mode restent '
      'saisis sans partir', (tester) async {
    EnrollmentSearchCommand? captured;
    await _pump(tester, dispatch: (cmd) => captured = cmd);

    await _switchToIdentity(tester);
    await _enterNames(tester);
    await _switchToClass(tester);
    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    final command = captured! as AcademicInfoSearchCommand;
    expect(command.schoolLevelGroupId, 'g1');
    expect(command.schoolLevelId, 'l1');
    // Les critères de l'autre mode ne voyagent pas : une classe entière ne
    // doit pas être silencieusement réduite à un élève oublié dans un champ.
    expect(command.firstName, isEmpty);
    expect(command.lastName, isEmpty);
    expect(command.surname, isEmpty);

    // ... mais ils sont toujours là quand on y revient.
    await _switchToIdentity(tester);
    expect(find.text('Kabongo'), findsOneWidget);
  });

  testWidgets('classe : le nom d\'affinage voyage avec le niveau', (
    tester,
  ) async {
    EnrollmentSearchCommand? captured;
    await _pump(tester, dispatch: (cmd) => captured = cmd);

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');
    // Le seul champ texte du mode classe est l'affinage.
    await tester.enterText(find.byType(TextField).first, 'kab');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    final command = captured! as AcademicInfoSearchCommand;
    expect(command.schoolLevelGroupId, 'g1');
    // Il emprunte la colonne « Nom » (raffinement PARTIEL côté projector), et
    // la capitalisation par défaut s'y applique comme partout.
    expect(command.lastName, 'Kab');
    expect(command.firstName, isEmpty);
    expect(command.surname, isEmpty);
  });

  testWidgets('l\'affinage n\'arme jamais la recherche à lui seul', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {});

    await tester.enterText(find.byType(TextField).first, 'kab');
    await tester.pumpAndSettle();

    expect(
      _searchButton(tester).onPressed,
      isNull,
      reason: 'c\'est la classe qui ouvre la recherche, jamais le nom',
    );
  });

  testWidgets('recherche désactivée tant que le mode actif est incomplet', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {});

    expect(_searchButton(tester).onPressed, isNull);

    // Un cycle seul ne suffit pas : il faut le niveau.
    await _selectCycle(tester, 'g1');
    expect(_searchButton(tester).onPressed, isNull);

    await _switchToIdentity(tester);
    // Un seul nom rempli → toujours désactivé (il en faut 3).
    await tester.enterText(find.byType(TextField).at(0), 'Kabongo');
    await tester.pumpAndSettle();
    expect(_searchButton(tester).onPressed, isNull);
  });

  testWidgets('un niveau armé ne survit pas à la bascule vers l\'identité', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {});

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');
    expect(_searchButton(tester).onPressed, isNotNull);

    await _switchToIdentity(tester);
    expect(
      _searchButton(tester).onPressed,
      isNull,
      reason: 'le mode identité est vide : il ne peut pas hériter de l\'autre',
    );
  });
}

SearchMode _shownMode(WidgetTester tester) =>
    tester.widget<SearchModeSwitch>(find.byType(SearchModeSwitch)).selected;

ElevatedButton _searchButton(WidgetTester tester) => tester
    .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Rechercher'));

Future<void> _switchToIdentity(WidgetTester tester) async {
  await tester.tap(find.text('Par identité'));
  await tester.pumpAndSettle();
}

Future<void> _switchToClass(WidgetTester tester) async {
  await tester.tap(find.text('Par classe'));
  await tester.pumpAndSettle();
}

/// Ordre des champs (SearchNameFields) : Nom, Post-nom, Prénom.
Future<void> _enterNames(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Kabongo');
  await tester.enterText(fields.at(1), 'Mwamba');
  await tester.enterText(fields.at(2), 'Daniel');
  await tester.pumpAndSettle();
}

// Les listes déroulantes du DS ouvrent un panneau en overlay : le test invoque
// directement leur `onChanged` plutôt que d'en simuler l'ouverture.
List<EteeloSelectInput<String>> _selects(WidgetTester tester) => tester
    .widgetList<EteeloSelectInput<String>>(
      find.byType(EteeloSelectInput<String>),
    )
    .toList(growable: false);

Future<void> _selectCycle(WidgetTester tester, String groupId) async {
  _selects(tester)[0].onChanged(groupId);
  await tester.pumpAndSettle();
}

Future<void> _selectLevel(WidgetTester tester, String levelKey) async {
  _selects(tester)[1].onChanged(levelKey);
  await tester.pumpAndSettle();
}
