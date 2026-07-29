import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
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

  testWidgets('rendu bi-mode (carte + 3 champs nom) sans erreur de layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, dispatch: (_) {});

    expect(tester.takeException(), isNull);
    expect(find.byType(BiToneSectionCard), findsOneWidget);
    expect(find.byType(EteeloTextInput), findsNWidgets(3));
    expect(find.text('Par nom'), findsOneWidget);
    expect(find.text('Par cycle / niveau'), findsOneWidget);
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    expect(find.textContaining('combiner les deux'), findsOneWidget);
  });

  testWidgets('recherche par noms : dispatch AcademicInfoSearchCommand', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    EnrollmentSearchCommand? captured;
    await _pump(tester, dispatch: (cmd) => captured = cmd);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Kabongo');
    await tester.enterText(fields.at(1), 'Mwamba');
    await tester.enterText(fields.at(2), 'Daniel');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    expect(captured, isA<AcademicInfoSearchCommand>());
    final command = captured! as AcademicInfoSearchCommand;
    expect(command.firstName, 'Daniel');
    expect(command.lastName, 'Kabongo');
    expect(command.surname, 'Mwamba');
    expect(command.schoolLevelGroupId, isEmpty);
    expect(command.schoolLevelId, isEmpty);
    // Miroir RE : pas de filtre de statut dans le formulaire.
    expect(command.status, isNull);
  });

  testWidgets('recherche désactivée tant qu\'aucun critère complet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, dispatch: (_) {});

    final searchButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Rechercher'),
    );
    expect(searchButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), 'Kabongo');
    await tester.pumpAndSettle();

    final stillDisabled = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Rechercher'),
    );
    expect(stillDisabled.onPressed, isNull);
  });
}
