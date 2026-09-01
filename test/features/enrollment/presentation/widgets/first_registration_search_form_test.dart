import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_registration_search_form.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_options.dart';
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
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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

  /// Le listing ouvre sans statut imposé : le champ doit le DIRE, et ne pas se
  /// replier sur la pastille d'un statut réel — le guichet croirait alors
  /// n'avoir sous les yeux qu'une part des dossiers.
  testWidgets('statut vide → le champ annonce « Tous les statuts »', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {}, status: kEnrollmentStatusFilterAll);

    expect(find.text('Tous les statuts'), findsOneWidget);
    expect(find.text('En cours'), findsNothing);
  });

  testWidgets(
    'rendu par défaut : bascule + cascade + statut, pas d\'identité',
    (tester) async {
      await _pump(tester, dispatch: (_) {});

      expect(tester.takeException(), isNull);
      expect(find.byType(BiToneSectionCard), findsOneWidget);
      expect(find.text('RECHERCHER PAR'), findsOneWidget);
      expect(find.text('Par classe'), findsOneWidget);
      expect(find.text('Par identité'), findsOneWidget);
      // Le seul champ du mode classe : l'affinage facultatif.
      expect(find.byType(EteeloTextInput), findsOneWidget);
      expect(find.text('Affiner par nom (facultatif)'), findsOneWidget);
      // 3 dropdowns : cycle + niveau (cascade) + statut (champ partagé).
      expect(find.byType(DropdownButton<String>), findsNWidgets(3));
    },
  );

  testWidgets('en mode identité, le statut reste hors de la bascule', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {});
    await _switchToIdentity(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(EteeloTextInput), findsNWidgets(3));
    // La cascade s'efface, le statut demeure : il borne les DEUX modes.
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets('identité : StandardSearchCommand borné au statut actif', (
    tester,
  ) async {
    EnrollmentSearchCommand? captured;
    await _pump(tester, dispatch: (cmd) => captured = cmd, status: 'COMPLETED');
    await _switchToIdentity(tester);
    await _enterNames(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    final command = captured! as StandardSearchCommand;
    expect(command.firstName, 'Daniel');
    expect(command.lastName, 'Kabongo');
    expect(command.surname, 'Mwamba');
    expect(command.status, 'COMPLETED');
  });

  testWidgets('classe : AcademicInfoSearchCommand avec statut', (tester) async {
    EnrollmentSearchCommand? captured;
    await _pump(tester, dispatch: (cmd) => captured = cmd);
    await _selectPrimaire1ere(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    final command = captured! as AcademicInfoSearchCommand;
    expect(command.schoolLevelGroupId, 'g1');
    expect(command.schoolLevelId, 'l1');
    expect(command.status, 'IN_PROGRESS');
  });

  testWidgets('classe : les noms saisis dans l\'autre mode ne partent pas', (
    tester,
  ) async {
    EnrollmentSearchCommand? captured;
    await _pump(tester, dispatch: (cmd) => captured = cmd);

    await _switchToIdentity(tester);
    await _enterNames(tester);
    await _switchToClass(tester);
    await _selectPrimaire1ere(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
    await tester.pumpAndSettle();

    final command = captured! as AcademicInfoSearchCommand;
    expect(command.schoolLevelGroupId, 'g1');
    expect(command.schoolLevelId, 'l1');
    // Un niveau entier ne doit pas être réduit en douce à un élève oublié
    // dans le formulaire de l'autre mode.
    expect(command.firstName, isEmpty);
    expect(command.lastName, isEmpty);
    expect(command.surname, isEmpty);
  });

  testWidgets(
    'classe : le nom d\'affinage voyage avec le niveau et le statut',
    (tester) async {
      EnrollmentSearchCommand? captured;
      await _pump(tester, dispatch: (cmd) => captured = cmd);
      await _selectPrimaire1ere(tester);

      // Le seul champ texte du mode classe est l'affinage.
      await tester.enterText(find.byType(TextField).first, 'kab');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Rechercher'));
      await tester.pumpAndSettle();

      final command = captured! as AcademicInfoSearchCommand;
      expect(command.schoolLevelId, 'l1');
      expect(command.lastName, 'Kab');
      expect(command.status, 'IN_PROGRESS');
    },
  );

  testWidgets(
    'changer de statut sans critère → notifie et redéclenche par statut seul',
    (tester) async {
      final dispatched = <EnrollmentSearchCommand>[];
      String? notifiedStatus;
      await _pump(
        tester,
        dispatch: dispatched.add,
        onStatusChanged: (status) => notifiedStatus = status,
      );

      await _changeStatus(tester);

      expect(notifiedStatus, isNotNull);
      expect(notifiedStatus, isNot('IN_PROGRESS'));
      expect(dispatched, hasLength(1));
      final command = dispatched.single as StandardSearchCommand;
      expect(command.status, notifiedStatus);
      expect(command.firstName, isNull);
    },
  );

  testWidgets('changer de statut en mode identité conserve le critère nom', (
    tester,
  ) async {
    final dispatched = <EnrollmentSearchCommand>[];
    String? notifiedStatus;
    await _pump(
      tester,
      dispatch: dispatched.add,
      onStatusChanged: (status) => notifiedStatus = status,
    );

    await _switchToIdentity(tester);
    await _enterNames(tester);
    await _changeStatus(tester);

    final command = dispatched.last as StandardSearchCommand;
    expect(command.firstName, 'Daniel');
    expect(command.lastName, 'Kabongo');
    expect(command.surname, 'Mwamba');
    expect(command.status, notifiedStatus);
  });

  testWidgets('recherche désactivée tant que le mode actif est incomplet', (
    tester,
  ) async {
    await _pump(tester, dispatch: (_) {});

    expect(_searchButton(tester).onPressed, isNull);

    await _switchToIdentity(tester);
    // Un seul nom rempli → toujours désactivé (il en faut 3).
    await tester.enterText(find.byType(TextField).at(0), 'Kabongo');
    await tester.pumpAndSettle();
    expect(_searchButton(tester).onPressed, isNull);
  });
}

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

Future<void> _selectPrimaire1ere(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButton<String>).at(0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Primaire').last);
  await tester.pumpAndSettle();

  await tester.tap(find.byType(DropdownButton<String>).at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text('1ère').last);
  await tester.pumpAndSettle();
}

/// Le champ statut est le DERNIER dropdown du formulaire, dans les deux modes.
Future<void> _changeStatus(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButton<String>).last);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownMenuItem<String>).last);
  await tester.pumpAndSettle();
}
