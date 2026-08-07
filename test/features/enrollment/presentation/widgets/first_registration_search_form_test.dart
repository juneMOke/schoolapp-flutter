import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_registration_search_form.dart';
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
  String status = 'IN_PROGRESS',
  ValueChanged<String>? onStatusChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: FirstRegistrationSearchForm(
          options: _options,
          isLoading: false,
          status: status,
          dispatch: dispatch,
          onStatusChanged: onStatusChanged,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'rendu bi-mode (carte + 3 champs nom + niveau + statut) sans erreur de layout',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, dispatch: (_) {});

      expect(tester.takeException(), isNull);
      expect(find.byType(BiToneSectionCard), findsOneWidget);
      expect(find.byType(EteeloTextInput), findsNWidgets(3));
      expect(find.text('Par élève'), findsOneWidget);
      expect(find.text('Par niveau visé'), findsOneWidget);
      // 3 dropdowns : cycle + niveau (cascade) + statut (champ partagé).
      expect(find.byType(DropdownButton<String>), findsNWidgets(3));
    },
  );

  testWidgets(
    'recherche par noms : dispatch StandardSearchCommand borné au statut actif',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      EnrollmentSearchCommand? captured;
      await _pump(
        tester,
        dispatch: (cmd) => captured = cmd,
        status: 'COMPLETED',
      );

      // Ordre des champs (SearchNameFields) : Nom, Post-nom, Prénom.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Kabongo');
      await tester.enterText(fields.at(1), 'Mwamba');
      await tester.enterText(fields.at(2), 'Daniel');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
      await tester.pumpAndSettle();

      expect(captured, isA<StandardSearchCommand>());
      final command = captured! as StandardSearchCommand;
      expect(command.firstName, 'Daniel');
      expect(command.lastName, 'Kabongo');
      expect(command.surname, 'Mwamba');
      expect(command.status, 'COMPLETED');
    },
  );

  testWidgets(
    'recherche par niveau visé : dispatch AcademicInfoSearchCommand avec statut',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      EnrollmentSearchCommand? captured;
      await _pump(
        tester,
        dispatch: (cmd) => captured = cmd,
        status: 'IN_PROGRESS',
      );

      await tester.tap(find.byType(DropdownButton<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Primaire').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1ère').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
      await tester.pumpAndSettle();

      expect(captured, isA<AcademicInfoSearchCommand>());
      final command = captured! as AcademicInfoSearchCommand;
      expect(command.schoolLevelGroupId, 'g1');
      expect(command.schoolLevelId, 'l1');
      expect(command.status, 'IN_PROGRESS');
    },
  );

  testWidgets(
    'noms + niveau tous deux renseignés : le niveau prime mais les noms sont '
    'transmis en plus (aucun critère perdu silencieusement)',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      EnrollmentSearchCommand? captured;
      await _pump(
        tester,
        dispatch: (cmd) => captured = cmd,
        status: 'IN_PROGRESS',
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Kabongo');
      await tester.enterText(fields.at(1), 'Mwamba');
      await tester.enterText(fields.at(2), 'Daniel');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Primaire').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1ère').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
      await tester.pumpAndSettle();

      expect(captured, isA<AcademicInfoSearchCommand>());
      final command = captured! as AcademicInfoSearchCommand;
      expect(command.schoolLevelGroupId, 'g1');
      expect(command.schoolLevelId, 'l1');
      expect(command.firstName, 'Daniel');
      expect(command.lastName, 'Kabongo');
      expect(command.surname, 'Mwamba');
      expect(command.status, 'IN_PROGRESS');
    },
  );

  testWidgets(
    'changer de statut sans critère → notifie et redéclenche par statut seul',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final dispatched = <EnrollmentSearchCommand>[];
      String? notifiedStatus;
      await _pump(
        tester,
        dispatch: dispatched.add,
        onStatusChanged: (status) => notifiedStatus = status,
      );

      // Le champ statut est le dernier dropdown du formulaire (après la
      // cascade cycle/niveau).
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenuItem<String>).last);
      await tester.pumpAndSettle();

      expect(notifiedStatus, isNotNull);
      expect(notifiedStatus, isNot('IN_PROGRESS'));
      expect(dispatched, hasLength(1));
      final command = dispatched.single as StandardSearchCommand;
      expect(command.status, notifiedStatus);
      expect(command.firstName, isNull);
    },
  );

  testWidgets(
    'changer de statut avec un nom déjà saisi conserve le critère nom',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final dispatched = <EnrollmentSearchCommand>[];
      String? notifiedStatus;
      await _pump(
        tester,
        dispatch: dispatched.add,
        onStatusChanged: (status) => notifiedStatus = status,
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Kabongo');
      await tester.enterText(fields.at(1), 'Mwamba');
      await tester.enterText(fields.at(2), 'Daniel');
      await tester.pumpAndSettle();

      // Le champ statut est le dernier dropdown du formulaire (après la
      // cascade cycle/niveau).
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenuItem<String>).last);
      await tester.pumpAndSettle();

      final command = dispatched.last as StandardSearchCommand;
      expect(command.firstName, 'Daniel');
      expect(command.lastName, 'Kabongo');
      expect(command.surname, 'Mwamba');
      expect(command.status, notifiedStatus);
    },
  );

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

    // Un seul nom rempli → toujours désactivé (il en faut 3).
    await tester.enterText(find.byType(TextField).at(0), 'Kabongo');
    await tester.pumpAndSettle();

    final stillDisabled = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Rechercher'),
    );
    expect(stillDisabled.onPressed, isNull);
  });
}
