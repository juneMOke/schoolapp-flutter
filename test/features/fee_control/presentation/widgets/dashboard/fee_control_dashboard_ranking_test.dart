import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_bloc.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/fee_control/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_group_row.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_ranking.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_summary_band.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/states/fee_control_dashboard_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class MockFeeControlDashboardBloc
    extends MockBloc<FeeControlDashboardEvent, FeeControlDashboardState>
    implements FeeControlDashboardBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// `null` = l'ensemble des droits n'a jamais été communiqué ; pas d'instance du
/// tout = aucun `AuthBloc` dans l'arbre. Les deux valent « inconnu ».
class _Session {
  const _Session(this.permissions);
  final List<String>? permissions;
}

FeeControlClassRow classRow(
  String? id,
  String? name, {
  required int settled,
  required int total,
}) => FeeControlClassRow(
  classroomId: id,
  name: name,
  breakdown: FeeControlBreakdown(settled: settled, none: total - settled),
  remaining: MoneyBag.empty,
);

final tBundles = [
  const SchoolLevelGroupBundle(
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
];

FeeControlGroupRow levelRow(
  String? level, {
  required int settled,
  required int total,
}) => FeeControlGroupRow(
  schoolLevelId: level,
  breakdown: FeeControlBreakdown(settled: settled, none: total - settled),
  remaining: MoneyBag.empty,
);

FeeControlDashboardSummary summaryOf(List<FeeControlGroupRow> groups) {
  var settled = 0;
  var none = 0;
  for (final g in groups) {
    settled += g.breakdown.settled;
    none += g.breakdown.none;
  }
  return FeeControlDashboardSummary(
    total: FeeControlBreakdown(settled: settled, none: none),
    remaining: MoneyBag.empty,
    groups: groups,
  );
}

Future<MockFeeControlDashboardBloc> _pump(
  WidgetTester tester,
  FeeControlDashboardState state, {
  bool showCycle = true,
  bool withBand = false,
  // ⚠️ Le squelette de chargement shimmer **sans fin** : `pumpAndSettle` ne s'y
  // stabilise jamais et expire. Les états animés se pompent d'une frame.
  bool settle = true,
  _Session? session,
}) async {
  pushedIntent = null;
  final bloc = MockFeeControlDashboardBloc();
  when(() => bloc.state).thenReturn(state);
  whenListen(
    bloc,
    const Stream<FeeControlDashboardState>.empty(),
    initialState: state,
  );

  Widget wrap(Widget child) {
    if (session == null) return child;
    final authBloc = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: session.permissions,
    );
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );
    return BlocProvider<AuthBloc>.value(value: authBloc, child: child);
  }

  final router = GoRouter(
    initialLocation: '/dash',
    routes: [
      GoRoute(
        path: '/dash',
        builder: (context, state) => wrap(
          BlocProvider<FeeControlDashboardBloc>.value(
            value: bloc,
            child: AppPageBackground(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (withBand) const FeeControlDashboardSummaryBand(),
                    FeeControlDashboardRanking(
                      labels: FeeControlDashboardLabels.from(tBundles),
                      academicYearId: 'ay-1',
                      showCycleInLabels: showCycle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // Le pont pousse cette route : l'observer ici prouve ce qui a voyagé.
      GoRoute(
        path: AppRoutesNames.feeControl,
        builder: (context, state) {
          pushedIntent = FeeControlIntent.fromRouteExtra(state.extra);
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
  return bloc;
}

/// L'intention reçue par l'écran nominatif, quand le pont a été emprunté.
FeeControlIntent? pushedIntent;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // ⚠️ Sans ce repli, le premier `any()` sur un événement lève un StateError
    // — et mocktail laisse alors les tests SUIVANTS dans un état où le mock ne
    // répond plus, ce qui les fait échouer sur des messages sans rapport.
    registerFallbackValue(const FeeControlDashboardRefreshRequested());
  });

  testWidgets('rien tant qu\'aucune lecture n\'a été demandée', (tester) async {
    await _pump(tester, const FeeControlDashboardState.initial());

    expect(find.byType(FeeControlDashboardGroupRow), findsNothing);
    expect(find.byType(EteeloListSkeleton), findsNothing);
  });

  testWidgets('chargement : le squelette partagé, pas un spinner ad hoc', (
    tester,
  ) async {
    await _pump(
      tester,
      const FeeControlDashboardState(status: EnrollmentLoadStatus.loading),
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
      const FeeControlDashboardState(
        status: EnrollmentLoadStatus.failure,
        errorType: EnrollmentErrorType.server,
        errorMessage: 'base fermée',
      ),
    );

    expect(find.byType(EnrollmentResultsErrorState), findsOneWidget);
  });

  testWidgets('succès sans personne : l\'état vide partagé', (tester) async {
    await _pump(
      tester,
      const FeeControlDashboardState(status: EnrollmentLoadStatus.success),
    );

    expect(find.byType(FeeControlDashboardEmptyState), findsOneWidget);
    expect(find.text('Aucun élève concerné'), findsOneWidget);
  });

  testWidgets('rend une ligne par groupe, dans l\'ordre du projecteur', (
    tester,
  ) async {
    await _pump(
      tester,
      FeeControlDashboardState(
        status: EnrollmentLoadStatus.success,
        summary: summaryOf([
          levelRow('lvl-2', settled: 2, total: 10),
          levelRow('lvl-1', settled: 9, total: 10),
        ]),
      ),
    );

    final rows = tester
        .widgetList<FeeControlDashboardGroupRow>(
          find.byType(FeeControlDashboardGroupRow),
        )
        .toList();
    expect(rows.length, 2);
    // L'écran ne retrie RIEN : l'ordre du classement est celui du projecteur,
    // le plus en retard en tête. Le retrier ici en ferait une seconde règle.
    expect(rows.first.label, 'Primaire · 2ème année');
    expect(rows.last.label, 'Primaire · 1ère année');
  });

  testWidgets('sans filtre de cycle, le nom du niveau est préfixé de son '
      'cycle — deux « 1ère année » seraient sinon indiscernables', (
    tester,
  ) async {
    await _pump(
      tester,
      FeeControlDashboardState(
        status: EnrollmentLoadStatus.success,
        summary: summaryOf([levelRow('lvl-1', settled: 1, total: 2)]),
      ),
    );

    expect(find.text('Primaire · 1ère année'), findsOneWidget);
  });

  testWidgets('avec un cycle filtré, le préfixe ne dirait que ce que le filtre '
      'affiche déjà', (tester) async {
    await _pump(
      tester,
      FeeControlDashboardState(
        status: EnrollmentLoadStatus.success,
        summary: summaryOf([levelRow('lvl-1', settled: 1, total: 2)]),
      ),
      showCycle: false,
    );

    expect(find.text('1ère année'), findsOneWidget);
    expect(find.text('Primaire · 1ère année'), findsNothing);
  });

  testWidgets('une créance sans niveau reste VISIBLE, et se nomme', (
    tester,
  ) async {
    await _pump(
      tester,
      FeeControlDashboardState(
        status: EnrollmentLoadStatus.success,
        summary: summaryOf([levelRow(null, settled: 0, total: 3)]),
      ),
    );

    expect(find.byType(FeeControlDashboardGroupRow), findsOneWidget);
    expect(find.text('Niveau non renseigné'), findsOneWidget);
  });

  testWidgets('un niveau que le référentiel ne connaît pas se dit AUTREMENT — '
      'une synchronisation le réparerait, pas une saisie', (tester) async {
    await _pump(
      tester,
      FeeControlDashboardState(
        status: EnrollmentLoadStatus.success,
        summary: summaryOf([levelRow('lvl-inconnu', settled: 0, total: 3)]),
      ),
    );

    expect(find.text('Niveau absent du référentiel'), findsOneWidget);
    expect(find.text('Niveau non renseigné'), findsNothing);
  });

  testWidgets('chaque ligne annonce sa part et son effectif', (tester) async {
    await _pump(
      tester,
      FeeControlDashboardState(
        status: EnrollmentLoadStatus.success,
        summary: summaryOf([levelRow('lvl-1', settled: 26, total: 31)]),
      ),
    );

    expect(find.text('84 %'), findsOneWidget);
    expect(find.text('26 sur 31'), findsOneWidget);
  });

  testWidgets('le bandeau emprunte l\'anatomie de l\'écran nominatif', (
    tester,
  ) async {
    await _pump(
      tester,
      FeeControlDashboardState(
        status: EnrollmentLoadStatus.success,
        summary: summaryOf([levelRow('lvl-1', settled: 26, total: 31)]),
      ),
      withBand: true,
    );

    expect(find.byType(EteeloKpiBand), findsOneWidget);
    expect(find.text('Élèves concernés'), findsOneWidget);
    expect(find.text('Payé'), findsOneWidget);
    // Même arrondi que partout : 26/31 = 83,9 %.
    expect(find.byKey(const ValueKey('Payé-26-84')), findsOneWidget);
  });

  group('dépliage', () {
    FeeControlDashboardState expanded({
      EnrollmentLoadStatus classesStatus = EnrollmentLoadStatus.success,
      List<FeeControlClassRow> classes = const <FeeControlClassRow>[],
      bool classroomsMissing = false,
    }) => FeeControlDashboardState(
      status: EnrollmentLoadStatus.success,
      summary: summaryOf([levelRow('lvl-1', settled: 5, total: 10)]),
      expandedLevelId: 'lvl-1',
      classesStatus: classesStatus,
      classes: classes,
      classroomsMissing: classroomsMissing,
    );

    testWidgets('un niveau replié n\'offre PAS ses classes', (tester) async {
      await _pump(
        tester,
        FeeControlDashboardState(
          status: EnrollmentLoadStatus.success,
          summary: summaryOf([levelRow('lvl-1', settled: 5, total: 10)]),
        ),
      );

      expect(find.byType(FeeControlDashboardGroupRow), findsOneWidget);
    });

    testWidgets('taper un niveau demande son dépliage', (tester) async {
      final bloc = await _pump(
        tester,
        FeeControlDashboardState(
          status: EnrollmentLoadStatus.success,
          summary: summaryOf([levelRow('lvl-1', settled: 5, total: 10)]),
        ),
      );

      await tester.tap(find.text('Primaire · 1ère année'));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(
          const FeeControlDashboardGroupToggled(
            academicYearId: 'ay-1',
            schoolLevelId: 'lvl-1',
          ),
        ),
      ).called(1);
    });

    testWidgets('le groupe « niveau non renseigné » est INERTE : pas de '
        'chevron qui n\'ouvre rien', (tester) async {
      final bloc = await _pump(
        tester,
        FeeControlDashboardState(
          status: EnrollmentLoadStatus.success,
          summary: summaryOf([levelRow(null, settled: 1, total: 3)]),
        ),
      );

      await tester.tap(find.text('Niveau non renseigné'));
      await tester.pumpAndSettle();

      verifyNever(
        () => bloc.add(any(that: isA<FeeControlDashboardGroupToggled>())),
      );
    });

    testWidgets('déplié : une sous-ligne par classe, les non-répartis nommés', (
      tester,
    ) async {
      await _pump(
        tester,
        expanded(
          classes: [
            classRow('c-a', '6e A', settled: 8, total: 10),
            classRow(null, null, settled: 0, total: 2),
          ],
        ),
      );

      expect(find.text('6e A'), findsOneWidget);
      expect(find.text('Non répartis'), findsOneWidget);
      // Le niveau plus ses deux classes.
      expect(find.byType(FeeControlDashboardGroupRow), findsNWidgets(3));
    });

    testWidgets('aucune classe SANS le droit : l\'écran nomme le DROIT, pas '
        'une synchronisation qui ne réparerait rien', (tester) async {
      await _pump(
        tester,
        expanded(classroomsMissing: true),
        session: const _Session(<String>[]),
      );

      expect(
        find.textContaining('un module auquel ce profil n\'a pas accès'),
        findsOneWidget,
      );
    });

    testWidgets('aucune classe AVEC le droit : le vrai « pas encore '
        'descendue »', (tester) async {
      await _pump(
        tester,
        expanded(classroomsMissing: true),
        session: _Session([Perm.classroomRead.wire]),
      );

      expect(
        find.textContaining('n\'est pas descendue sur cet appareil'),
        findsOneWidget,
      );
    });

    testWidgets('droits inconnus : l\'ancien message, jamais l\'accusation', (
      tester,
    ) async {
      await _pump(
        tester,
        expanded(classroomsMissing: true),
        session: const _Session(null),
      );

      expect(
        find.textContaining('n\'est pas descendue sur cet appareil'),
        findsOneWidget,
      );
    });

    testWidgets('lecture des classes en échec : le dit, et laisse le niveau '
        'lisible', (tester) async {
      await _pump(
        tester,
        expanded(classesStatus: EnrollmentLoadStatus.failure),
        settle: false,
      );

      expect(
        find.text(
          'Les classes de ce niveau n\'ont pas pu être lues sur cet '
          'appareil.',
        ),
        findsOneWidget,
      );
      expect(find.text('Primaire · 1ère année'), findsOneWidget);
    });
  });

  group('les non-facturés', () {
    FeeControlDashboardState withUnbilled(int? unbilled) =>
        FeeControlDashboardState(
          status: EnrollmentLoadStatus.success,
          summary: summaryOf([levelRow('lvl-1', settled: 8, total: 10)]),
          unbilled: unbilled,
        );

    testWidgets('la note se lit À CÔTÉ du bandeau, jamais dans le taux', (
      tester,
    ) async {
      await _pump(tester, withUnbilled(12), withBand: true);

      expect(
        find.text('12 élèves inscrits ne portent pas ce frais'),
        findsOneWidget,
      );
      // Le taux, lui, ignore ces douze-là : 8 soldés sur 10 concernés.
      expect(find.byKey(const ValueKey('Payé-8-80')), findsOneWidget);
    });

    testWidgets('un seul non-facturé se dit au SINGULIER', (tester) async {
      await _pump(tester, withUnbilled(1), withBand: true);

      expect(
        find.text('1 élève inscrit ne porte pas ce frais'),
        findsOneWidget,
      );
    });

    testWidgets(
      'compte inconnu : la note se TAIT plutôt que d\'annoncer zéro',
      (tester) async {
        await _pump(tester, withUnbilled(null), withBand: true);

        expect(find.textContaining('ne porte'), findsNothing);
        expect(find.textContaining('ne portent'), findsNothing);
      },
    );

    testWidgets('zéro non-facturé : rien à signaler, rien d\'affiché', (
      tester,
    ) async {
      await _pump(tester, withUnbilled(0), withBand: true);

      expect(find.textContaining('ne portent pas ce frais'), findsNothing);
    });
  });

  group('pont vers l\'écran nominatif', () {
    FeeControlDashboardState withQuery({
      String? expandedLevelId,
      List<FeeControlClassRow> classes = const <FeeControlClassRow>[],
    }) => FeeControlDashboardState(
      status: EnrollmentLoadStatus.success,
      summary: summaryOf([levelRow('lvl-1', settled: 5, total: 10)]),
      lastQuery: const FeeControlDashboardQuery(
        academicYearId: 'ay-1',
        feeCode: 'TUITION',
      ),
      expandedLevelId: expandedLevelId,
      classesStatus: expandedLevelId == null
          ? EnrollmentLoadStatus.initial
          : EnrollmentLoadStatus.success,
      classes: classes,
    );

    testWidgets('un niveau transmet son cycle, son niveau et le frais LU', (
      tester,
    ) async {
      await _pump(tester, withQuery());

      await tester.tap(find.byIcon(Icons.people_outline).first);
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

    testWidgets('une classe transmet EN PLUS son identifiant', (tester) async {
      await _pump(
        tester,
        withQuery(
          expandedLevelId: 'lvl-1',
          classes: [classRow('c-a', '6e A', settled: 8, total: 10)],
        ),
      );

      // La seconde icône est celle de la classe : la première est au niveau.
      await tester.tap(find.byIcon(Icons.people_outline).last);
      await tester.pumpAndSettle();

      expect(pushedIntent!.classroomId, 'c-a');
      expect(pushedIntent!.schoolLevelId, 'lvl-1');
    });

    testWidgets('les non-répartis n\'offrent PAS le passage : ils ne forment '
        'pas une classe à transmettre', (tester) async {
      await _pump(
        tester,
        withQuery(
          expandedLevelId: 'lvl-1',
          classes: [classRow(null, null, settled: 0, total: 3)],
        ),
      );

      // Une seule icône : celle du niveau. La ligne des non-répartis n'en a pas.
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('le groupe « niveau non renseigné » n\'offre pas le passage '
        'non plus', (tester) async {
      await _pump(
        tester,
        FeeControlDashboardState(
          status: EnrollmentLoadStatus.success,
          summary: summaryOf([levelRow(null, settled: 1, total: 3)]),
          lastQuery: const FeeControlDashboardQuery(
            academicYearId: 'ay-1',
            feeCode: 'TUITION',
          ),
        ),
      );

      expect(find.byIcon(Icons.people_outline), findsNothing);
    });

    testWidgets('sans lecture aboutie, le passage ne mène nulle part', (
      tester,
    ) async {
      await _pump(
        tester,
        FeeControlDashboardState(
          status: EnrollmentLoadStatus.success,
          summary: summaryOf([levelRow('lvl-1', settled: 5, total: 10)]),
        ),
      );

      await tester.tap(find.byIcon(Icons.people_outline).first);
      await tester.pumpAndSettle();

      expect(pushedIntent, isNull);
    });
  });

  group('revue — finition', () {
    testWidgets('un niveau que le référentiel ne rattache à AUCUN cycle '
        'n\'offre pas le passage : le bouton ne ferait rien', (tester) async {
      await _pump(
        tester,
        FeeControlDashboardState(
          status: EnrollmentLoadStatus.success,
          summary: summaryOf([levelRow('lvl-inconnu', settled: 1, total: 4)]),
          lastQuery: const FeeControlDashboardQuery(
            academicYearId: 'ay-1',
            feeCode: 'TUITION',
          ),
        ),
      );

      expect(find.text('Niveau absent du référentiel'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsNothing);
    });

    testWidgets('le reste à recouvrer se dit PAR DEVISE, jamais en un total', (
      tester,
    ) async {
      await _pump(
        tester,
        FeeControlDashboardState(
          status: EnrollmentLoadStatus.success,
          summary: FeeControlDashboardSummary(
            total: const FeeControlBreakdown(settled: 1, none: 1),
            remaining: MoneyBag.of([
              Money.parse(150000, 'USD'),
              Money.parse(300000, 'CDF'),
            ]),
            groups: [levelRow('lvl-1', settled: 1, total: 2)],
          ),
        ),
        withBand: true,
      );

      final note = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').startsWith('Reste à recouvrer'),
        ),
      );
      // Les deux devises côte à côte, chacune avec son symbole : les sommer
      // écrirait un montant qui n'existe pas — leur rapport d'échelle est de
      // ×2 800.
      expect(note.data, contains('FC'));
      expect(note.data, contains('\$'));
      expect(note.data, contains('·'));
    });

    testWidgets('rien à recouvrer : la ligne se tait', (tester) async {
      await _pump(
        tester,
        FeeControlDashboardState(
          status: EnrollmentLoadStatus.success,
          summary: summaryOf([levelRow('lvl-1', settled: 2, total: 2)]),
        ),
        withBand: true,
      );

      expect(find.textContaining('Reste à recouvrer'), findsNothing);
    });
  });
}
