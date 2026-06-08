import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  const cycle = ClassesOrganisationCycleOption(
    id: 'cycle-1',
    label: 'Primaire',
    levels: <ClassesOrganisationLevelOption>[
      ClassesOrganisationLevelOption(
        schoolLevelGroupId: 'cycle-1',
        schoolLevelGroupName: 'Primaire',
        schoolLevelId: 'level-1',
        schoolLevelName: '5e',
        splitIntoClassrooms: false,
        classrooms: [],
      ),
    ],
  );

  Future<void> pumpForm(
    WidgetTester tester, {
    String? selectedCycleId,
    String? selectedLevelId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClassesOrganisationSearchForm(
              schoolYear: '2026-2027',
              cycles: const [cycle],
              selectedCycleId: selectedCycleId,
              selectedLevelId: selectedLevelId,
              onCycleChanged: (_) {},
              onLevelChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('affiche l eyebrow terre-cuite avec l annee scolaire', (
    tester,
  ) async {
    await pumpForm(tester);

    expect(
      find.text('COMPOSITION DES CLASSES · ANNÉE 2026-2027'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('affiche le titre de selection du niveau', (tester) async {
    await pumpForm(tester);

    expect(find.text('Sélection du niveau à organiser'), findsOneWidget);
  });

  testWidgets('rend les deux Select Cycle et Niveau', (tester) async {
    await pumpForm(tester);

    expect(find.text('Cycle'), findsWidgets);
    expect(find.text('Niveau'), findsWidgets);
  });

  testWidgets('invite a choisir un cycle tant qu aucun cycle n est pris', (
    tester,
  ) async {
    await pumpForm(tester);

    expect(find.text('Choisissez d\'abord un cycle'), findsOneWidget);
  });
}
