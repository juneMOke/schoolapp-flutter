import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_dashboard_page.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/avatars/person_sync_avatar.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_sync_insight.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/states/hr_dashboard_results_error_state.dart';

import '../hr_personnel_builders.dart';
import 'hr_dashboard_harness.dart';
import 'hr_personnel_harness.dart';

/// Le tableau de bord lit le serveur — chiffres, liste et PDF sur la même
/// question — et ne garde du fichier local que ce qui n'est pas encore parti.
void main() {
  final rows = [
    serverRow(
      'a',
      lastName: 'KALALA',
      firstName: 'Didier',
      seniorityYears: 3,
      contractKind: StaffContractKind.vacataire,
    ),
    serverRow(
      'b',
      lastName: 'MAYALA',
      firstName: 'Ruth',
      sex: StaffSex.female,
      seniorityYears: 8,
    ),
    serverRow(
      'c',
      lastName: 'ÉLONGO',
      firstName: 'Béatrice',
      sex: StaffSex.female,
      category: HrCategoryKey.administrative,
      jobTitle: 'Économe',
      seniorityYears: 16,
    ),
  ];

  List<String> rosterIds(WidgetTester tester) => [
    for (final row
        in tester.widget<DataTableView>(find.byType(DataTableView)).rows)
      row.id,
  ];

  /// La pastille de l'agent [id] dans le tableau, ou `null` sans pastille.
  RecordSyncState? syncOf(WidgetTester tester, String id) => tester
      .widgetList<PersonSyncAvatar>(
        find.descendant(
          of: find.byType(DataTableView),
          matching: find.byType(PersonSyncAvatar),
        ),
      )
      .where((avatar) => avatar.personId == id)
      .firstOrNull
      ?.sync;

  HrStaffMembersCubit members(WidgetTester tester) =>
      tester.element(find.byType(HrDashboardScreen)).read();

  testWidgets('les trois indicateurs sont ceux du serveur', (tester) async {
    final server = FakeHrStaffDashboard(rows)
      ..statsOverride = statsOf(rows).withDean;
    await pumpHrDashboard(tester, server: server);

    // Trois pavés pleins : l'icône et le libellé sur une ligne.
    final cards = tester.widgetList<EteeloKpiCard>(find.byType(EteeloKpiCard));
    expect(cards.map((card) => card.data.isFilled), [true, true, true]);
    expect(find.text('EFFECTIF'), findsOneWidget);
    expect(find.text('ENSEIGNANTS'), findsOneWidget);
    expect(find.text('2 femmes · 1 homme'), findsOneWidget);
    expect(find.text('67 % · 1 hors enseignement'), findsOneWidget);
    // (3 + 8 + 16) / 3 = 9,0
    expect(find.text('9,0 ans'), findsOneWidget);
    expect(find.text('doyen : Béatrice ÉLONGO · 16 ans'), findsOneWidget);
    expect(
      find.text("Qui travaille à l'école · 3 agents · année 2026-2027"),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la première page part triée par nom, sans critère', (
    tester,
  ) async {
    final server = FakeHrStaffDashboard(rows);
    await pumpHrDashboard(tester, server: server);

    expect(server.asked.first, (HrRosterQuery.none, 0));
    expect(rosterIds(tester), ['a', 'b', 'c']);
    expect(find.text('3 agents · tout le personnel'), findsOneWidget);
  });

  testWidgets('le tableau des reçus : teinté, une colonne par fait', (
    tester,
  ) async {
    await pumpHrDashboard(tester, server: FakeHrStaffDashboard(rows));

    // Toutes les sections teintées, comme à la Boutique.
    expect(
      tester
          .widgetList<EteeloStatsCard>(find.byType(EteeloStatsCard))
          .map((card) => card.tone),
      everyElement(isNotNull),
    );
    final table = tester.widget<DataTableView>(find.byType(DataTableView));
    expect(table.config.tone, isNotNull);
    expect(table.config.phoneLayout, DataTablePhoneLayout.cards);
    // Sans `hr.document.read`, le serveur tait le dossier : pas de colonne.
    expect(table.config.columns.map((column) => column.label), [
      'Agent',
      'Catégorie',
      'Contrat',
      'Ancienneté',
    ]);
  });

  testWidgets('le dossier fourni ouvre sa colonne', (tester) async {
    await pumpHrDashboard(
      tester,
      server: FakeHrStaffDashboard([
        serverRow('a', dossier: const HrDossierCount(provided: 2, required: 5)),
        serverRow('b', lastName: 'MBUYI'),
      ]),
    );

    final table = tester.widget<DataTableView>(find.byType(DataTableView));
    expect(table.config.columns.last.label, 'Dossier');
    // Chaque ligne garde une cellule par colonne, même sans compte.
    expect(table.rows.map((row) => row.cells.length), [5, 5]);
    expect(find.byTooltip('2 pièce(s) sur 5 au dossier'), findsOneWidget);
  });

  testWidgets('rien en attente : pas d\'alerte', (tester) async {
    await pumpHrDashboard(tester, server: FakeHrStaffDashboard(rows));
    expect(find.byType(HrSyncInsight), findsNothing);
  });

  testWidgets('une fiche hors ligne lève l\'alerte et marque sa ligne', (
    tester,
  ) async {
    await pumpHrDashboard(
      tester,
      server: FakeHrStaffDashboard(rows),
      local: snapshotOf([agent('a', syncState: RecordSyncState.pending)]),
    );

    expect(find.byType(HrSyncInsight), findsOneWidget);
    expect(find.text('1 modification encore sur la tablette'), findsOneWidget);
    expect(syncOf(tester, 'a'), RecordSyncState.pending);
    expect(syncOf(tester, 'b'), RecordSyncState.synced);
  });

  testWidgets('taper une catégorie la demande au serveur ; re-taper la '
      'retire', (tester) async {
    final server = FakeHrStaffDashboard(rows);
    await pumpHrDashboard(tester, server: server);

    await tester.tap(find.text('Administratif').first);
    await tester.pumpAndSettle();
    expect(server.asked.last.$1.category, HrCategoryKey.administrative);
    expect(rosterIds(tester), ['c']);
    expect(find.text('filtre actif'), findsOneWidget);
    expect(find.text('1 agent · Administratif'), findsOneWidget);

    await tester.tap(find.text('Administratif').first);
    await tester.pumpAndSettle();
    expect(rosterIds(tester), hasLength(3));
    expect(find.text('filtre actif'), findsNothing);
  });

  testWidgets('la recherche part au serveur, de la première page', (
    tester,
  ) async {
    final server = FakeHrStaffDashboard(rows);
    await pumpHrDashboard(tester, server: server);

    await tester.enterText(find.byType(EditableText).first, 'ruth');
    await tester.pump();
    await tester.pump();

    expect(server.asked.last, (const HrRosterQuery(text: 'ruth'), 0));
    expect(rosterIds(tester), ['b']);
  });

  testWidgets('l\'ordre choisi part au serveur', (tester) async {
    final server = FakeHrStaffDashboard(rows);
    await pumpHrDashboard(tester, server: server);

    await members(tester).setSort(HrRosterSort.nameDescending);
    await tester.pump();

    expect(server.asked.last.$1.sort, HrRosterSort.nameDescending);
    expect(rosterIds(tester), ['c', 'b', 'a']);
  });

  testWidgets('par ancienneté : la date absente en fin de liste', (
    tester,
  ) async {
    final server = FakeHrStaffDashboard([
      serverRow('r', lastName: 'RECENT', entryDate: '2024-09-01'),
      serverRow('x', lastName: 'SANS', entryDate: null, seniorityYears: null),
      serverRow('o', lastName: 'ANCIEN', entryDate: '2001-09-01'),
    ]);
    await pumpHrDashboard(tester, server: server);

    await members(tester).setSort(HrRosterSort.oldest);
    await tester.pump();

    expect(server.asked.last.$1.sort, HrRosterSort.oldest);
    expect(rosterIds(tester), ['o', 'r', 'x']);
  });

  testWidgets('sans ligne, le PDF est désactivé et « Tout afficher » vide', (
    tester,
  ) async {
    await pumpHrDashboard(tester, server: FakeHrStaffDashboard(rows));

    await tester.enterText(find.byType(EditableText).first, 'introuvable');
    await tester.pump();
    await tester.pump();

    expect(find.text('Aucun agent ne correspond'), findsOneWidget);
    final pdf = tester.widget<EteeloButton>(
      find.widgetWithText(EteeloButton, 'PDF'),
    );
    expect(pdf.onPressed, isNull);

    await tester.tap(find.text('Tout afficher'));
    await tester.pump();
    await tester.pump();
    expect(rosterIds(tester), hasLength(3));
  });

  testWidgets('le PDF reprend la question de la liste affichée', (
    tester,
  ) async {
    final server = FakeHrStaffDashboard(rows);
    await pumpHrDashboard(tester, server: server);
    await members(tester).setCategory(HrCategoryKey.teacher);
    await tester.pump();

    await tester.tap(find.widgetWithText(EteeloButton, 'PDF'));
    await tester.pump();

    expect(server.printed, [
      const HrRosterQuery(category: HrCategoryKey.teacher),
    ]);
  });

  testWidgets('au-delà de 20 agents, la liste se lit page par page', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < 25; i++)
        serverRow('m$i', lastName: 'AGENT ${i.toString().padLeft(2, '0')}'),
    ];
    final server = FakeHrStaffDashboard(many);
    await pumpHrDashboard(tester, server: server, size: const Size(1280, 3200));

    expect(rosterIds(tester), hasLength(20));
    expect(find.text('Page 1 / 2'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Page suivante'));
    await tester.tap(find.byTooltip('Page suivante'));
    await tester.pump();
    await tester.pump();

    expect(server.asked.last.$2, 1);
    expect(rosterIds(tester), hasLength(5));
  });

  testWidgets('hors ligne : l\'erreur réseau, pas des zéros', (tester) async {
    final server = FakeHrStaffDashboard(rows)
      ..failure = const NetworkFailure('Aucune connexion.');
    await pumpHrDashboard(tester, server: server);

    expect(find.byType(HrDashboardResultsErrorState), findsOneWidget);
    expect(find.text('Pas de connexion'), findsOneWidget);
    expect(find.text('EFFECTIF'), findsNothing);
  });

  testWidgets('un sexe non renseigné se dit, la somme tient', (tester) async {
    await pumpHrDashboard(
      tester,
      server: FakeHrStaffDashboard([
        serverRow('a', sex: StaffSex.female),
        serverRow('b', sex: null),
      ]),
    );

    expect(find.text('1 femme · 0 homme · 1 non renseigné'), findsOneWidget);
  });

  testWidgets('un fichier vide propose d\'ajouter un agent', (tester) async {
    await pumpHrDashboard(tester, server: FakeHrStaffDashboard(const []));

    expect(find.text('Aucun agent dans le fichier'), findsOneWidget);
    expect(find.text('Liste du personnel'), findsNothing);
    expect(find.text('Ouvrir le fichier'), findsOneWidget);
  });

  testWidgets('vide pour le serveur, mais des agents en attente : ni « vide » '
      'ni « ajouter », qui inviterait au doublon', (tester) async {
    await pumpHrDashboard(
      tester,
      server: FakeHrStaffDashboard(const []),
      local: snapshotOf([agent('a', syncState: RecordSyncState.pending)]),
    );

    expect(find.byType(HrSyncInsight), findsOneWidget);
    expect(find.text('Rien encore sur le serveur'), findsOneWidget);
    expect(find.text('Aucun agent dans le fichier'), findsNothing);
    expect(find.text('Ajouter un agent'), findsNothing);
  });

  testWidgets('chiffres là, liste en panne : l\'erreur reste dans la carte', (
    tester,
  ) async {
    final server = FakeHrStaffDashboard(rows)
      ..membersFailure = const ServerFailure('500');
    await pumpHrDashboard(tester, server: server);

    expect(find.text('EFFECTIF'), findsOneWidget);
    expect(find.text('Le serveur n\'a pas répondu'), findsOneWidget);
    expect(
      tester
          .widget<EteeloButton>(find.widgetWithText(EteeloButton, 'PDF'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('une panne serveur se dit serveur, pas « cette tablette »', (
    tester,
  ) async {
    final server = FakeHrStaffDashboard(rows)
      ..failure = const ServerFailure('500');
    await pumpHrDashboard(tester, server: server);

    expect(find.text('Le serveur n\'a pas répondu'), findsWidgets);
    expect(find.textContaining('sur cette tablette'), findsNothing);
  });

  testWidgets(
    'fichier local illisible : aucune pastille ne prétend « à jour »',
    (tester) async {
      final source = MockStaffSnapshotSource();
      when(() => source.watch(any())).thenReturn(() {});
      when(() => source.pull()).thenAnswer((_) async {});
      when(() => source.read()).thenAnswer(
        (_) async =>
            const Left<Failure, StaffFileSnapshot>(StorageFailure('illisible')),
      );
      await pumpHrDashboard(
        tester,
        server: FakeHrStaffDashboard(rows),
        source: source,
      );

      expect(rosterIds(tester), hasLength(3));
      // La légende de la carte garde ses pastilles ; aucune ligne n'en porte.
      expect(
        find.descendant(
          of: find.byType(DataTableView),
          matching: find.byType(RecordSyncDot),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DataTableView),
          matching: find.byType(PersonAvatar),
        ),
        findsNWidgets(3),
      );
    },
  );

  testWidgets('un 429 sur le PDF : le bouton attend, désarmé, et le dit', (
    tester,
  ) async {
    final server = FakeHrStaffDashboard(rows)
      ..reportFailure = const TooManyRequestsFailure(
        retryAfter: Duration(seconds: 30),
      );
    await pumpHrDashboard(tester, server: server);

    await tester.tap(find.widgetWithText(EteeloButton, 'PDF'));
    await tester.pump();
    await tester.pump();

    final waiting = find.widgetWithText(EteeloButton, 'Patientez…');
    expect(waiting, findsOneWidget);
    expect(tester.widget<EteeloButton>(waiting).onPressed, isNull);
    expect(
      find.text('Un document est déjà en préparation. Réessayez dans 30 s.'),
      findsOneWidget,
    );
    // L'attente court encore : elle s'achève avec le test.
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('pendant la frappe, le PDF n\'imprime pas l\'ancienne liste', (
    tester,
  ) async {
    await pumpHrDashboard(tester, server: FakeHrStaffDashboard(rows));
    members(tester).setText('ruth');
    await tester.pump();

    expect(
      tester
          .widget<EteeloButton>(find.widgetWithText(EteeloButton, 'PDF'))
          .onPressed,
      isNull,
    );
    // La recherche part : le minuteur de frappe se dénoue.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
  });

  testWidgets('un envoi achevé fait relire le serveur', (tester) async {
    var file = snapshotOf(const []);
    final source = MockStaffSnapshotSource();
    when(() => source.watch(any())).thenReturn(() {});
    when(() => source.pull()).thenAnswer((_) async {});
    when(() => source.read()).thenAnswer((_) async => Right(file));
    final server = FakeHrStaffDashboard(rows);
    final local = await pumpHrDashboard(tester, server: server, source: source);
    final statsBefore = server.statsCalls;
    final askedBefore = server.asked.length;

    // La fin d'un envoi réveille le fichier local, qui a changé.
    file = snapshotOf([agent('z')]);
    await local.refresh();
    await tester.pump();
    await tester.pump();

    expect(server.statsCalls, statsBefore + 1);
    expect(server.asked.length, askedBefore + 1);
  });

  testWidgets('une catégorie se pose aussi au lecteur d\'écran', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpHrDashboard(tester, server: FakeHrStaffDashboard(rows));

    tester.semantics.tap(find.semantics.byLabel('Administratif · 1 agent'));
    await tester.pumpAndSettle();

    expect(members(tester).state.query.category, HrCategoryKey.administrative);
    semantics.dispose();
  });
}

extension on HrStaffStats {
  /// Le doyen que le serveur désigne : Béatrice ÉLONGO, 16 ans.
  HrStaffStats get withDean => HrStaffStats(
    asOf: asOf,
    headcount: headcount,
    sexes: sexes,
    averageSeniority: averageSeniority,
    seniorityBase: seniorityBase,
    dean: const HrDean(
      staffMemberId: 'c',
      lastName: 'ÉLONGO',
      middleName: null,
      firstName: 'Béatrice',
      entryDate: '2010-09-01',
      years: 16,
    ),
    categories: categories,
  );
}
