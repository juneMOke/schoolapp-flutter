import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/pre_registration_search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _options = [
  SearchLevelOption(
    schoolLevelGroupId: 'g1',
    schoolLevelId: 'l1',
    label: 'Primaire - 1ère',
  ),
  SearchLevelOption(
    schoolLevelGroupId: 'g2',
    schoolLevelId: 'l3',
    label: 'Secondaire - 6ème',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required void Function(EnrollmentSearchCommand) dispatch,
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
        child: PreRegistrationSearchForm(
          options: _options,
          isLoading: false,
          dispatch: dispatch,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la carte s\'ouvre sur « Par classe », bascule annoncée', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {});

    expect(tester.takeException(), isNull);
    expect(find.byType(BiToneSectionCard), findsOneWidget);
    expect(find.text('RECHERCHER PAR'), findsOneWidget);
    expect(find.text('Par classe'), findsOneWidget);
    expect(find.text('Par identité'), findsOneWidget);
    expect(find.byType(EteeloSelectInput<String>), findsNWidgets(2));
    // Le seul champ du mode classe : l'affinage facultatif.
    expect(find.byType(EteeloTextInput), findsOneWidget);
    expect(find.text('Affiner par nom (facultatif)'), findsOneWidget);
  });

  testWidgets('identité : dispatch AcademicInfoSearchCommand sans niveau', (
    tester,
  ) async {
    EnrollmentSearchCommand? captured;
    await _pump(tester, dispatch: (cmd) => captured = cmd);
    await _switchToIdentity(tester);

    expect(find.byType(EteeloTextInput), findsNWidgets(3));

    // Ordre des champs (SearchNameFields) : Nom, Post-nom, Prénom.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Kabongo');
    await tester.enterText(fields.at(1), 'Mwamba');
    await tester.enterText(fields.at(2), 'Daniel');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    final command = captured! as AcademicInfoSearchCommand;
    expect(command.firstName, 'Daniel');
    expect(command.lastName, 'Kabongo');
    expect(command.surname, 'Mwamba');
    expect(command.schoolLevelGroupId, isEmpty);
    expect(command.schoolLevelId, isEmpty);
    // Miroir RE : pas de filtre de statut dans le formulaire.
    expect(command.status, isNull);
  });

  testWidgets('classe : seul le niveau part', (tester) async {
    EnrollmentSearchCommand? captured;
    await _pump(tester, dispatch: (cmd) => captured = cmd);

    _selects(tester)[0].onChanged('g2');
    await tester.pumpAndSettle();
    _selects(tester)[1].onChanged('g2::l3');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    final command = captured! as AcademicInfoSearchCommand;
    expect(command.schoolLevelGroupId, 'g2');
    expect(command.schoolLevelId, 'l3');
    expect(command.firstName, isEmpty);
  });

  testWidgets('recherche désactivée tant que le mode actif est incomplet', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {});

    expect(_searchButton(tester).onPressed, isNull);

    await _switchToIdentity(tester);
    // Aucun nom rempli → toujours désactivé.
    expect(_searchButton(tester).onPressed, isNull);

    // Un seul nom suffit désormais : les trois se combinent en OU, celui qui
    // ne connaît que le nom d'un élève doit pouvoir chercher.
    await tester.enterText(find.byType(TextField).at(0), 'Kabongo');
    await tester.pumpAndSettle();
    expect(_searchButton(tester).onPressed, isNotNull);
  });
}

ElevatedButton _searchButton(WidgetTester tester) => tester
    .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Rechercher'));

Future<void> _switchToIdentity(WidgetTester tester) async {
  await tester.tap(find.text('Par identité'));
  await tester.pumpAndSettle();
}

// Les listes déroulantes du DS ouvrent un panneau en overlay : le test invoque
// directement leur `onChanged` plutôt que d'en simuler l'ouverture.
List<EteeloSelectInput<String>> _selects(WidgetTester tester) => tester
    .widgetList<EteeloSelectInput<String>>(
      find.byType(EteeloSelectInput<String>),
    )
    .toList(growable: false);
