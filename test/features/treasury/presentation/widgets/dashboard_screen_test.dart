import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_reports_cubit.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_dashboard_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_evolution_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_overview_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/dashboard_screen.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

class _MockRepository extends Mock implements TreasuryDashboardRepository {}

class _MockReports extends Mock implements TreasuryReportsRepository {}

Future<_MockRepository> _pump(
  WidgetTester tester, {
  TreasuryOverview? overview,
  VoidCallback? onOpenClosing,
}) async {
  final repo = _MockRepository();
  final reports = _MockReports();
  when(() => reports.list(any(), any())).thenAnswer(
    (_) async => Right(
      CashReportPage(
        items: [
          cashReport(),
          cashReport(
            id: 'RJ-20261021',
            status: CashReportStatus.finalReport,
            title: 'Mercredi 21 octobre 2026',
          ),
        ],
        number: 0,
        totalPages: 1,
      ),
    ),
  );
  when(
    () => repo.overview(),
  ).thenAnswer((_) async => Right(overview ?? treasuryOverview()));
  when(
    () => repo.evolution(
      any(),
      from: any(named: 'from'),
      to: any(named: 'to'),
    ),
  ).thenAnswer((_) async => Right(treasuryEvolution()));
  await tester.pumpWidget(
    treasuryHost(
      BlocProvider(
        create: (_) => TreasuryOverviewCubit(repo)..load(),
        child: TreasuryDashboardScreen(
          onOpenClosing: onOpenClosing,
          evolutionCubit: (today) => TreasuryEvolutionCubit(repo, today: today),
          reportsCubit: (today) => CashReportsCubit(reports, today: today),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(() {
    registerFallbackValue(EvolutionPeriod.month);
    registerFallbackValue(CashReportKind.daily);
  });

  testAtReferenceFormats('deux caisses et leur évolution', (tester, _) async {
    await _pump(tester, onOpenClosing: () {});
    expect(find.text('Combien avons-nous en caisse ?'), findsOneWidget);
    expect(find.textContaining('2026-2027'), findsOneWidget);
  });

  testWidgets('chaque caisse dans sa devise, montants exacts', (tester) async {
    setTestWindow(tester, const Size(1280, 1600));
    await _pump(tester);
    expect(
      find.text(TreasuryFormat.money(481900, TreasuryCurrency.usd)),
      findsOneWidget,
    );
    expect(
      find.text(TreasuryFormat.money(344500000, TreasuryCurrency.cdf)),
      findsOneWidget,
    );
    expect(find.text('À clôturer'), findsOneWidget);
    expect(find.text('Clôturée 17:45'), findsOneWidget);
  });

  testWidgets('le bandeau dit la granularité retenue par le serveur', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1600));
    await _pump(tester);
    expect(find.textContaining('19 jours de caisse'), findsOneWidget);
    expect(
      find.textContaining('affichage semaine par semaine'),
      findsOneWidget,
    );
    expect(find.textContaining('▼ -8 %'), findsOneWidget);
  });

  testWidgets('toucher une caisse ouvre sa clôture', (tester) async {
    setTestWindow(tester, const Size(1280, 1600));
    var opened = 0;
    await _pump(tester, onOpenClosing: () => opened++);
    await tester.tap(find.text('Voir la clôture de la caisse').first);
    expect(opened, 1);
  });

  testWidgets('aucune caisse : l état vide, sans courbe', (tester) async {
    setTestWindow(tester, const Size(1280, 1600));
    await _pump(tester, overview: treasuryOverview(registers: const []));
    expect(find.text('Aucune caisse'), findsOneWidget);
    expect(find.text('Évolution des caisses'), findsNothing);
  });

  group('TreasuryEvolutionCubit', () {
    test(
      'une période libre dont la fin précède le début : aucun appel',
      () async {
        final repo = _MockRepository();
        when(
          () => repo.evolution(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => Right(treasuryEvolution()));
        final cubit = TreasuryEvolutionCubit(repo, today: demoDay);
        addTearDown(cubit.close);
        await cubit.periodChanged(EvolutionPeriod.custom);
        clearInteractions(repo);
        await cubit.customRangeChanged(
          DateTime(2026, 10, 20),
          DateTime(2026, 10, 1),
        );
        expect(cubit.state.rangeError, isTrue);
        verifyNever(
          () => repo.evolution(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        );
      },
    );

    test('ce mois par défaut, 30 derniers jours pour la période libre', () {
      final cubit = TreasuryEvolutionCubit(_MockRepository(), today: demoDay);
      addTearDown(cubit.close);
      expect(cubit.state.period, EvolutionPeriod.month);
      expect(cubit.state.customFrom, DateTime(2026, 9, 23));
      expect(cubit.state.customTo, demoDay);
    });
  });

  testWidgets('les tranches à venir gardent leur place sur l axe', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1600));
    await _pump(tester);
    // Cinq semaines au mois, la dernière à venir : son libellé reste.
    expect(find.text('S5'), findsOneWidget);
  });

  test(
    'INVALID_RANGE sur une période libre : recalage sur le jour du serveur',
    () async {
      final repo = _MockRepository();
      final ahead = DateTime(2026, 10, 25);
      when(
        () => repo.evolution(
          any(),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((invocation) async {
        final to = invocation.namedArguments[#to] as DateTime?;
        if (to == ahead) {
          return const Left(
            TreasuryRefusalFailure(
              TreasuryRefusal.invalidRange,
              details: {'businessDate': '2026-10-22'},
            ),
          );
        }
        return Right(treasuryEvolution());
      });
      final cubit = TreasuryEvolutionCubit(repo, today: ahead);
      addTearDown(cubit.close);
      await cubit.periodChanged(EvolutionPeriod.custom);
      expect(cubit.state.customTo, demoDay);
      expect(cubit.state.status, TreasuryEvolutionStatus.ready);
    },
  );

  testWidgets('les rapports : statut, référence, devises', (tester) async {
    setTestWindow(tester, const Size(1280, 2400));
    await _pump(tester);
    expect(find.text('Rapports de caisse'), findsOneWidget);
    expect(find.text('Provisoire · non clôturé'), findsOneWidget);
    expect(find.text('Définitif'), findsOneWidget);
    expect(find.text('RJ-20261022 · USD · CDF'), findsOneWidget);
  });

  group('CashReportsCubit', () {
    test(
      '« Période » : le rapport généré s ajoute en tête, sans doublon',
      () async {
        final reports = _MockReports();
        final period = cashReport(
          id: 'RP-20261009-1022',
          kind: CashReportKind.period,
        );
        when(
          () => reports.period(any(), any()),
        ).thenAnswer((_) async => Right(period));
        final cubit = CashReportsCubit(reports, today: demoDay);
        addTearDown(cubit.close);
        await cubit.kindChanged(CashReportKind.period);
        await cubit.generatePeriod();
        await cubit.generatePeriod();
        expect(cubit.state.periodReports, [period]);
        verifyNever(() => reports.list(any(), any()));
      },
    );

    test('une fin avant le début ne génère rien', () async {
      final reports = _MockReports();
      final cubit = CashReportsCubit(reports, today: demoDay);
      addTearDown(cubit.close);
      cubit.rangeChanged(DateTime(2026, 10, 20), DateTime(2026, 10, 1));
      expect(await cubit.generatePeriod(), isNull);
      verifyNever(() => reports.period(any(), any()));
    });
  });
}
