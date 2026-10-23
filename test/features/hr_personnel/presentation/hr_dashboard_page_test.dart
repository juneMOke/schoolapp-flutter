import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_dashboard_page.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_roster_row.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_sync_insight.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../hr_personnel_builders.dart';
import 'hr_personnel_harness.dart';

void main() {
  final file = snapshotOf([
    agent(
      'a',
      lastName: 'Kalala',
      firstName: 'Didier',
      sex: StaffSex.male,
      entryDate: '2023-09-15',
      contracts: [period(StaffContractKind.vacataire)],
    ),
    agent(
      'b',
      lastName: 'Mayala',
      firstName: 'Ruth',
      sex: StaffSex.female,
      entryDate: '2018-09-01',
    ),
    agent(
      'c',
      lastName: 'Élongo',
      firstName: 'Béatrice',
      sex: StaffSex.female,
      category: StaffCategory.administrative,
      jobTitle: 'Économe',
      entryDate: '2010-09-01',
    ),
  ]);

  List<String> rosterIds(WidgetTester tester) => [
    for (final row in tester.widgetList<HrRosterRow>(find.byType(HrRosterRow)))
      row.row.member.id,
  ];

  testWidgets('les trois indicateurs portent sur tout le fichier', (
    tester,
  ) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrDashboardScreen(),
    );

    expect(find.text('EFFECTIF'), findsOneWidget);
    expect(find.text('2 femmes · 1 homme'), findsOneWidget);
    expect(find.text('67 % · 1 hors enseignement'), findsOneWidget);
    // (3 + 8 + 16) / 3 = 9,0
    expect(find.text('9,0 ans'), findsOneWidget);
    expect(find.text('doyen : Béatrice Élongo · 16 ans'), findsOneWidget);
    expect(
      find.text("Qui travaille à l'école · 3 agents · année 2026-2027"),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('l\'alerte synchro n\'existe que s\'il reste un envoi', (
    tester,
  ) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrDashboardScreen(),
    );
    expect(find.byType(HrSyncInsight), findsNothing);
  });

  testWidgets('une fiche hors ligne lève l\'alerte et reste comptée', (
    tester,
  ) async {
    await pumpHrScreen(
      tester,
      snapshot: snapshotOf([
        agent('a', staffNumber: null, syncState: RecordSyncState.pending),
      ]),
      screen: const HrDashboardScreen(),
    );

    expect(find.byType(HrSyncInsight), findsOneWidget);
    expect(find.text('1 modification encore sur la tablette'), findsOneWidget);
    expect(find.text('1 agent · tout le personnel'), findsOneWidget);
  });

  testWidgets('la liste suit le nom, puis l\'ancienneté', (tester) async {
    final cubit = await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrDashboardScreen(),
    );

    expect(rosterIds(tester), ['c', 'a', 'b']);
    cubit.setSort(HrRosterSort.oldest);
    await tester.pump();
    expect(rosterIds(tester), ['c', 'b', 'a']);
  });

  testWidgets('taper une catégorie filtre la liste ; re-taper le retire', (
    tester,
  ) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrDashboardScreen(),
    );

    await tester.tap(find.text('Administratif').first);
    await tester.pumpAndSettle();
    expect(rosterIds(tester), ['c']);
    expect(find.text('filtre actif'), findsOneWidget);
    expect(find.text('Administratif · 1'), findsOneWidget);
    expect(find.text('1 agent · Administratif'), findsOneWidget);

    await tester.tap(find.text('Administratif').first);
    await tester.pumpAndSettle();
    expect(rosterIds(tester), hasLength(3));
    expect(find.text('filtre actif'), findsNothing);
  });

  testWidgets('« beatrice » trouve « Béatrice »', (tester) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrDashboardScreen(),
    );

    await tester.enterText(find.byType(EditableText).first, 'beatrice');
    await tester.pump();

    expect(rosterIds(tester), ['c']);
  });

  testWidgets('sans ligne, le PDF est désactivé et « Tout afficher » vide', (
    tester,
  ) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrDashboardScreen(),
    );

    await tester.enterText(find.byType(EditableText).first, 'introuvable');
    await tester.pump();

    expect(find.text('Aucun agent ne correspond'), findsOneWidget);
    final pdf = tester.widget<EteeloButton>(
      find.widgetWithText(EteeloButton, 'PDF'),
    );
    expect(pdf.onPressed, isNull);

    await tester.tap(find.text('Tout afficher'));
    await tester.pump();
    expect(rosterIds(tester), hasLength(3));
  });

  testWidgets('un sexe non renseigné se dit, la somme tient', (tester) async {
    await pumpHrScreen(
      tester,
      snapshot: snapshotOf([
        agent('a', sex: StaffSex.female),
        agent('b', sex: null, category: null),
      ]),
      screen: const HrDashboardScreen(),
    );

    expect(find.text('1 femme · 0 homme · 1 non renseigné'), findsOneWidget);
    expect(find.text('Non renseignée'), findsWidgets);
    expect(HrCategoryKey.of(null), HrCategoryKey.unknown);
  });

  testWidgets('un fichier vide propose d\'ajouter un agent', (tester) async {
    await pumpHrScreen(
      tester,
      snapshot: snapshotOf(const []),
      screen: const HrDashboardScreen(),
    );

    expect(find.text('Aucun agent dans le fichier'), findsOneWidget);
    expect(find.text('Liste du personnel'), findsNothing);
    expect(find.text('Ouvrir le fichier'), findsOneWidget);
  });

  testWidgets('tient en largeur de téléphone', (tester) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrDashboardScreen(),
      size: const Size(390, 2600),
    );
    expect(tester.takeException(), isNull);
  });
}
