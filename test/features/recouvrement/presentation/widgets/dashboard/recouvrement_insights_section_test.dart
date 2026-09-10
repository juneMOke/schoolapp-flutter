import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_insights_section.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockDashboard
    extends MockBloc<RecouvrementDashboardEvent, RecouvrementDashboardState>
    implements RecouvrementDashboardBloc {}

RecouvrementFeeRate rate(
  String feeCode, {
  int expected = 30000,
  int paid = 12000,
  int remaining = 18000,
}) => RecouvrementFeeRate(
  feeCode: feeCode,
  currency: 'USD',
  expectedInCents: expected,
  paidInCents: paid,
  remainingInCents: remaining,
);

RecouvrementCurrencyGroup currencyGroup(List<RecouvrementFeeRate> fees) {
  var e = 0, p = 0, r = 0;
  for (final f in fees) {
    e += f.expectedInCents;
    p += f.paidInCents;
    r += f.remainingInCents;
  }
  return RecouvrementCurrencyGroup(
    currency: 'USD',
    fees: fees,
    expectedInCents: e,
    paidInCents: p,
    remainingInCents: r,
  );
}

RecouvrementGroupRow level(
  String id, {
  required int settled,
  required int none,
}) => RecouvrementGroupRow(
  schoolLevelId: id,
  breakdown: FeeControlBreakdown(settled: settled, none: none),
  remaining: MoneyBag.of([Money.parse(1000, 'USD')]),
);

void main() {
  late _MockDashboard dashboard;

  setUp(() => dashboard = _MockDashboard());

  Future<void> pump(
    WidgetTester tester, {
    required RecouvrementDashboardState state,
    RecouvrementSimulationCubit? simulation,
    void Function(String)? onControl,
  }) async {
    whenListen(
      dashboard,
      const Stream<RecouvrementDashboardState>.empty(),
      initialState: state,
    );
    final cubit = simulation ?? RecouvrementSimulationCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MultiBlocProvider(
              providers: [
                BlocProvider<RecouvrementDashboardBloc>.value(value: dashboard),
                BlocProvider<RecouvrementSimulationCubit>.value(value: cubit),
              ],
              child: RecouvrementInsightsSection(
                labels: FeeControlDashboardLabels.from(const []),
                showCycleInLabels: false,
                onControlRequested: onControl,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  RecouvrementDashboardState ready({
    List<RecouvrementCurrencyGroup> rates = const [],
    List<RecouvrementGroupRow> groups = const [],
  }) => RecouvrementDashboardState(
    status: EnrollmentLoadStatus.success,
    figures: const RecouvrementKeyFigures(
      total: 10,
      none: 2,
      partial: 3,
      settled: 5,
      expected: MoneyBag.empty,
      paid: MoneyBag.empty,
      remaining: MoneyBag.empty,
    ),
    rates: rates,
    ranking: RecouvrementRankingSummary(
      total: const FeeControlBreakdown(settled: 5, none: 5),
      remaining: MoneyBag.empty,
      groups: groups,
    ),
  );

  group('le frais le plus en retard', () {
    testWidgets('désigne le taux le plus BAS, pas le premier venu', (
      tester,
    ) async {
      await pump(
        tester,
        state: ready(
          rates: [
            currencyGroup([
              rate('TUITION', expected: 100000, paid: 80000, remaining: 20000),
              rate('BOOKS', expected: 10000, paid: 2000, remaining: 8000),
            ]),
          ],
        ),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(
        find.textContaining(l10n.studentChargeFeeCodeBooks),
        findsOneWidget,
      );
    });

    testWidgets(
      'ÉCARTE les postes sans attendu — leur 100 % ne veut rien dire',
      (tester) async {
        await pump(
          tester,
          state: ready(
            rates: [
              currencyGroup([
                rate(
                  'TUITION',
                  expected: 100000,
                  paid: 80000,
                  remaining: 20000,
                ),
                rate('BOOKS', expected: 0, paid: 0, remaining: 0),
              ]),
            ],
          ),
        );

        final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
        // Le poste dormant a un taux de 100 : trié naïvement il arriverait
        // dernier, mais il ne doit pas être DÉSIGNÉ non plus.
        expect(
          find.textContaining(l10n.studentChargeFeeCodeTuition),
          findsOneWidget,
        );
      },
    );

    testWidgets('l\'action n\'apparaît que si quelqu\'un l\'écoute', (
      tester,
    ) async {
      await pump(
        tester,
        state: ready(
          rates: [
            currencyGroup([rate('TUITION')]),
          ],
        ),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.recouvrementInsightControlAction), findsNothing);

      await pump(
        tester,
        state: ready(
          rates: [
            currencyGroup([rate('TUITION')]),
          ],
        ),
        onControl: (_) {},
      );
      expect(find.text(l10n.recouvrementInsightControlAction), findsOneWidget);
    });
  });

  group('l\'écart entre groupes', () {
    testWidgets('se tait sous DEUX groupes — un écart avec soi n\'existe pas', (
      tester,
    ) async {
      await pump(
        tester,
        state: ready(groups: [level('lvl-1', settled: 5, none: 5)]),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.recouvrementInsightSpreadTitle), findsNothing);
    });

    testWidgets('se tait quand les deux bouts sont à ÉGALITÉ', (tester) async {
      await pump(
        tester,
        state: ready(
          groups: [
            level('lvl-1', settled: 5, none: 5),
            level('lvl-2', settled: 5, none: 5),
          ],
        ),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.recouvrementInsightSpreadTitle), findsNothing);
    });

    testWidgets('parle dès qu\'il y a un écart réel', (tester) async {
      await pump(
        tester,
        state: ready(
          groups: [
            level('lvl-1', settled: 1, none: 9),
            level('lvl-2', settled: 9, none: 1),
          ],
        ),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.recouvrementInsightSpreadTitle), findsOneWidget);
    });
  });

  group('la lecture de simulation', () {
    testWidgets('est TOUJOURS rendue — même quand la mesure tient', (
      tester,
    ) async {
      await pump(tester, state: ready());

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(
        find.text(l10n.recouvrementInsightSimulationTitle),
        findsOneWidget,
      );
    });
  });

  group('la condition de rendu', () {
    testWidgets('rien pendant le chargement : on ne squelettise pas du texte', (
      tester,
    ) async {
      await pump(
        tester,
        state: const RecouvrementDashboardState(
          status: EnrollmentLoadStatus.loading,
        ),
      );

      expect(find.byType(Card), findsNothing);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.recouvrementInsightSimulationTitle), findsNothing);
    });

    testWidgets('rien sur un écran vide : il n\'y a rien à interpréter', (
      tester,
    ) async {
      await pump(
        tester,
        state: const RecouvrementDashboardState(
          status: EnrollmentLoadStatus.success,
        ),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.recouvrementInsightSimulationTitle), findsNothing);
    });
  });
}
