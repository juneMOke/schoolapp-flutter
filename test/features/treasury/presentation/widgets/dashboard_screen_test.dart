import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_dashboard_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_evolution_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_overview_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/dashboard_screen.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

class _MockRepository extends Mock implements TreasuryDashboardRepository {}

Future<_MockRepository> _pump(
  WidgetTester tester, {
  TreasuryOverview? overview,
  VoidCallback? onOpenClosing,
}) async {
  final repo = _MockRepository();
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
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => TreasuryOverviewCubit(repo)..load()),
          BlocProvider(
            create: (_) => TreasuryEvolutionCubit(repo, today: demoDay)..load(),
          ),
        ],
        child: TreasuryDashboardScreen(onOpenClosing: onOpenClosing),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(() => registerFallbackValue(EvolutionPeriod.month));

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
}
