import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_breakdown_tile.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_cycles_section.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/states/recouvrement_dashboard_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class MockRecouvrementDashboardBloc
    extends MockBloc<RecouvrementDashboardEvent, RecouvrementDashboardState>
    implements RecouvrementDashboardBloc {}

const tBundles = [
  SchoolLevelGroupBundle(
    group: SchoolLevelGroup(
      id: 'g1',
      name: 'Primaire',
      code: 'PRIM',
      displayOrder: 1,
    ),
    levels: [
      SchoolLevel(
        id: 'lvl-1',
        name: '1ère année',
        code: 'P1',
        displayOrder: 1,
        splitIntoClassrooms: true,
      ),
      SchoolLevel(
        id: 'lvl-2',
        name: '2ème année',
        code: 'P2',
        displayOrder: 2,
        splitIntoClassrooms: true,
      ),
    ],
  ),
  SchoolLevelGroupBundle(
    group: SchoolLevelGroup(
      id: 'g2',
      name: 'Secondaire',
      code: 'SEC',
      displayOrder: 2,
    ),
    levels: [
      SchoolLevel(
        id: 'lvl-7',
        name: '7ème année',
        code: 'S1',
        displayOrder: 1,
        splitIntoClassrooms: true,
      ),
    ],
  ),
];

RecouvrementGroupRow levelRow(
  String? level, {
  int settled = 0,
  int partial = 0,
  int none = 0,
}) => RecouvrementGroupRow(
  schoolLevelId: level,
  breakdown: FeeControlBreakdown(
    settled: settled,
    partial: partial,
    none: none,
  ),
  remaining: MoneyBag.empty,
);

RecouvrementDashboardState ready(
  List<RecouvrementGroupRow> groups, {
  bool withQuery = true,
}) {
  var settled = 0;
  var partial = 0;
  var none = 0;
  for (final group in groups) {
    settled += group.breakdown.settled;
    partial += group.breakdown.partial;
    none += group.breakdown.none;
  }
  return RecouvrementDashboardState(
    status: EnrollmentLoadStatus.success,
    ranking: RecouvrementRankingSummary(
      total: FeeControlBreakdown(
        settled: settled,
        partial: partial,
        none: none,
      ),
      remaining: MoneyBag.empty,
      groups: groups,
    ),
    lastQuery: withQuery
        ? const RecouvrementQuery(academicYearId: 'ay-1', feeCodes: ['TUITION'])
        : null,
  );
}

/// L'intention reçue par l'écran nominatif, quand l'œil a été emprunté.
FeeControlIntent? pushedIntent;

Future<void> _pump(
  WidgetTester tester,
  RecouvrementDashboardState state, {
  Stream<RecouvrementDashboardState>? stream,
  // ⚠️ Le squelette de chargement shimmer **sans fin** : `pumpAndSettle` ne s'y
  // stabilise jamais et expire. Les états animés se pompent d'une frame.
  bool settle = true,
}) async {
  pushedIntent = null;
  final bloc = MockRecouvrementDashboardBloc();
  whenListen(
    bloc,
    stream ?? const Stream<RecouvrementDashboardState>.empty(),
    initialState: state,
  );

  final router = GoRouter(
    initialLocation: '/dash',
    routes: [
      GoRoute(
        path: '/dash',
        builder: (context, _) => BlocProvider<RecouvrementDashboardBloc>.value(
          value: bloc,
          child: AppPageBackground(
            child: SingleChildScrollView(
              child: RecouvrementCyclesSection(
                labels: FeeControlDashboardLabels.from(tBundles),
              ),
            ),
          ),
        ),
      ),
      // L'œil pousse cette route : l'observer ici prouve ce qui a voyagé.
      GoRoute(
        path: AppRoutesNames.recouvrementControl,
        builder: (context, routeState) {
          pushedIntent = FeeControlIntent.fromRouteExtra(routeState.extra);
          return const Scaffold(body: Text('ÉCRAN NOMINATIF'));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Les lignes affichées, de haut en bas — cycles et niveaux mêlés.
List<String> tileLabels(WidgetTester tester) => tester
    .widgetList<RecouvrementBreakdownTile>(
      find.byType(RecouvrementBreakdownTile),
    )
    .map((tile) => tile.label)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('les états', () {
    testWidgets('rien tant qu\'aucune lecture n\'a été demandée', (
      tester,
    ) async {
      await _pump(tester, const RecouvrementDashboardState.initial());

      expect(find.byType(RecouvrementBreakdownTile), findsNothing);
      expect(find.byType(EteeloListSkeleton), findsNothing);
    });

    testWidgets('chargement : le squelette partagé, pas un spinner ad hoc', (
      tester,
    ) async {
      await _pump(
        tester,
        const RecouvrementDashboardState(status: EnrollmentLoadStatus.loading),
        settle: false,
      );

      expect(find.byType(EteeloListSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('échec : l\'état d\'erreur partagé, avec une reprise', (
      tester,
    ) async {
      await _pump(
        tester,
        const RecouvrementDashboardState(
          status: EnrollmentLoadStatus.failure,
          errorType: EnrollmentErrorType.server,
          errorMessage: 'base fermée',
        ),
      );

      expect(find.byType(EnrollmentResultsErrorState), findsOneWidget);
    });

    testWidgets('succès sans personne : l\'état vide partagé, et NU — un vide '
        'n\'a pas de titre de section', (tester) async {
      await _pump(
        tester,
        const RecouvrementDashboardState(status: EnrollmentLoadStatus.success),
      );

      expect(find.byType(RecouvrementDashboardEmptyState), findsOneWidget);
      expect(find.text('Aucun élève concerné'), findsOneWidget);
      expect(find.byType(BiToneSectionCard), findsNothing);
    });

    testWidgets('la section vit dans une carte titrée, comme les autres', (
      tester,
    ) async {
      await _pump(tester, ready([levelRow('lvl-1', settled: 2)]));

      expect(
        find.descendant(
          of: find.byType(BiToneSectionCard),
          matching: find.text('Où en est chaque niveau'),
        ),
        findsOneWidget,
      );
    });
  });

  group('l\'arbre', () {
    testWidgets('une ligne par cycle, dans l\'ordre de l\'école — pas dans '
        'celui du retard', (tester) async {
      await _pump(
        tester,
        ready([
          // Le plus en retard : en tête du classement du projecteur.
          levelRow('lvl-7', none: 5),
          levelRow('lvl-1', settled: 4),
        ]),
      );

      expect(tileLabels(tester), ['Primaire', 'Secondaire']);
    });

    testWidgets('plusieurs cycles : repliés, leurs niveaux ne s\'affichent '
        'pas', (tester) async {
      await _pump(
        tester,
        ready([levelRow('lvl-1', settled: 4), levelRow('lvl-7', none: 5)]),
      );

      expect(find.text('1ère année'), findsNothing);
      expect(find.text('7ème année'), findsNothing);
    });

    testWidgets('taper un cycle l\'ouvre sur ses niveaux, dans l\'ordre du '
        'référentiel ; le retaper le referme', (tester) async {
      await _pump(
        tester,
        ready([
          levelRow('lvl-2', none: 3),
          levelRow('lvl-1', settled: 3),
          levelRow('lvl-7', settled: 1),
        ]),
      );

      await tester.tap(find.text('Primaire'));
      await tester.pumpAndSettle();
      expect(tileLabels(tester), [
        'Primaire',
        '1ère année',
        '2ème année',
        'Secondaire',
      ]);

      await tester.tap(find.text('Primaire'));
      await tester.pumpAndSettle();
      expect(tileLabels(tester), ['Primaire', 'Secondaire']);
    });

    testWidgets('un cycle SEUL — sous un filtre de cycle — s\'ouvre de '
        'lui-même : le replier ne laisserait rien à lire', (tester) async {
      await _pump(
        tester,
        ready([levelRow('lvl-2', none: 1), levelRow('lvl-1', settled: 1)]),
      );

      expect(tileLabels(tester), ['Primaire', '1ère année', '2ème année']);
    });

    testWidgets('sous son cycle, le niveau ne répète pas le nom du cycle', (
      tester,
    ) async {
      await _pump(tester, ready([levelRow('lvl-1', settled: 1)]));

      expect(find.text('1ère année'), findsOneWidget);
      expect(find.text('Primaire · 1ère année'), findsNothing);
    });

    testWidgets('le cycle somme ses niveaux : trois comptes, effectif, part', (
      tester,
    ) async {
      await _pump(
        tester,
        ready([
          levelRow('lvl-1', settled: 5, partial: 2, none: 4),
          levelRow('lvl-2', settled: 3, partial: 1, none: 1),
        ]),
      );

      // Le cycle : 8 + 3 + 5 = 16 élèves, dont la moitié a tout payé.
      expect(find.text('8 tout payé'), findsOneWidget);
      expect(find.text('3 partiellement'), findsOneWidget);
      expect(find.text('5 rien payé'), findsOneWidget);
      expect(find.text('16 élèves'), findsOneWidget);
      expect(find.text('50 %'), findsOneWidget);
      // Et chaque niveau dit les siens.
      expect(find.text('11 élèves'), findsOneWidget);
      expect(find.text('60 %'), findsOneWidget);
    });

    testWidgets('ce que le référentiel ne sait pas rattacher reste VISIBLE, '
        'dans son propre groupe, en dernier', (tester) async {
      await _pump(
        tester,
        ready([
          levelRow(null, none: 2),
          levelRow('lvl-inconnu', none: 1),
          levelRow('lvl-1', settled: 1),
        ]),
      );

      expect(tileLabels(tester), ['Primaire', 'Non rattachés à un cycle']);

      await tester.tap(find.text('Non rattachés à un cycle'));
      await tester.pumpAndSettle();

      // Deux absences, deux noms : l'une se répare par une synchronisation,
      // l'autre non.
      expect(tileLabels(tester), [
        'Primaire',
        'Non rattachés à un cycle',
        'Niveau absent du référentiel',
        'Niveau non renseigné',
      ]);
    });

    testWidgets('un cycle ouvert le RESTE à la lecture suivante — cocher un '
        'frais ne referme pas ce qu\'on lit —, avec les chiffres neufs', (
      tester,
    ) async {
      final controller = StreamController<RecouvrementDashboardState>();
      addTearDown(controller.close);
      await _pump(
        tester,
        ready([levelRow('lvl-1', settled: 1), levelRow('lvl-7', none: 1)]),
        stream: controller.stream,
      );

      await tester.tap(find.text('Secondaire'));
      await tester.pumpAndSettle();
      expect(find.text('7ème année'), findsOneWidget);

      controller.add(
        ready([levelRow('lvl-1', settled: 2), levelRow('lvl-7', none: 3)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('7ème année'), findsOneWidget);
      // Le cycle et son niveau disent tous deux la nouvelle lecture.
      expect(find.text('3 rien payé'), findsNWidgets(2));
    });
  });

  group('l\'œil', () {
    testWidgets('transmet le cycle, le niveau et le frais LU', (tester) async {
      await _pump(tester, ready([levelRow('lvl-1', settled: 1, none: 1)]));

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(pushedIntent, isNotNull);
      // Le cycle vient du RÉFÉRENTIEL, par le niveau : le filtre de l'écran
      // peut valoir « tous les cycles », que l'écran nominatif refuserait.
      expect(pushedIntent!.schoolLevelGroupId, 'g1');
      expect(pushedIntent!.schoolLevelId, 'lvl-1');
      expect(pushedIntent!.classroomId, isNull);
      // Le frais vient de `lastQuery` : ce sont les chiffres AFFICHÉS qui
      // ouvrent la liste, pas des critères qu'on aurait changés depuis.
      expect(pushedIntent!.feeCode, 'TUITION');
    });

    testWidgets('se nomme : l\'infobulle dit quel niveau il ouvre', (
      tester,
    ) async {
      await _pump(tester, ready([levelRow('lvl-1', settled: 1)]));

      expect(find.byTooltip('Voir le détail : 1ère année'), findsOneWidget);
    });

    testWidgets('un cycle n\'a pas d\'œil : c\'est un niveau qu\'on ouvre', (
      tester,
    ) async {
      await _pump(
        tester,
        ready([levelRow('lvl-1', settled: 1), levelRow('lvl-2', none: 1)]),
      );

      // Un cycle ouvert, deux niveaux : deux yeux, pas trois.
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
    });

    testWidgets('ni la ligne sans niveau ni le niveau inconnu n\'offrent le '
        'passage : un œil qui n\'ouvre rien mentirait', (tester) async {
      await _pump(
        tester,
        ready([levelRow(null, none: 1), levelRow('lvl-inconnu', none: 1)]),
      );

      expect(find.text('Niveau non renseigné'), findsOneWidget);
      expect(find.text('Niveau absent du référentiel'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('sans lecture aboutie, l\'œil ne mène nulle part', (
      tester,
    ) async {
      await _pump(
        tester,
        ready([levelRow('lvl-1', settled: 1)], withQuery: false),
      );

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(pushedIntent, isNull);
    });
  });
}
