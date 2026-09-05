import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_window_tabs.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockBloc extends MockBloc<EnrollmentStatsEvent, EnrollmentStatsState>
    implements EnrollmentStatsBloc {}

Future<void> _pump(
  WidgetTester tester,
  EnrollmentStatsBloc bloc, {
  double width = 900,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: BlocProvider<EnrollmentStatsBloc>.value(
              value: bloc,
              child: const EnrollmentDashboardWindowTabs(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EnrollmentStatsBloc _blocOn(EnrollmentStatsState state) {
  final bloc = _MockBloc();
  whenListen(
    bloc,
    const Stream<EnrollmentStatsState>.empty(),
    initialState: state,
  );
  return bloc;
}

void main() {
  setUpAll(() => registerFallbackValue(const EnrollmentStatsRequested()));

  testWidgets('les cinq fenêtres sont proposées', (tester) async {
    final bloc = _blocOn(const EnrollmentStatsState());
    addTearDown(bloc.close);
    await _pump(tester, bloc);

    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Cette semaine'), findsOneWidget);
    expect(find.text('Ce mois'), findsOneWidget);
    expect(find.text('Année'), findsOneWidget);
    expect(find.text('Période précise'), findsOneWidget);
  });

  testWidgets('choisir un onglet demande la fenêtre correspondante', (
    tester,
  ) async {
    final bloc = _blocOn(const EnrollmentStatsState());
    addTearDown(bloc.close);
    await _pump(tester, bloc);

    await tester.tap(find.text('Ce mois'));
    await tester.pumpAndSettle();

    // Choisir une fenêtre ET demander ses chiffres sont le MÊME geste : il n'y
    // a pas d'évènement « changer d'onglet » séparé qui laisserait exister un
    // onglet actif sans chiffres correspondants.
    verify(
      () => bloc.add(
        const EnrollmentStatsRequested(window: EnrollmentStatsWindow.month()),
      ),
    ).called(1);
  });

  testWidgets('retaper l\'onglet déjà actif ne relance rien', (tester) async {
    final bloc = _blocOn(const EnrollmentStatsState());
    addTearDown(bloc.close);
    await _pump(tester, bloc);

    await tester.tap(find.text('Année'));
    await tester.pumpAndSettle();

    verifyNever(() => bloc.add(any()));
  });

  group('le libellé de plage décrit la fenêtre COMPTÉE', () {
    testWidgets('une journée se nomme entièrement', (tester) async {
      final bloc = _blocOn(
        EnrollmentStatsState(
          window: EnrollmentStatsWindow.day(DateTime(2026, 9, 5)),
        ),
      );
      addTearDown(bloc.close);
      await _pump(tester, bloc);

      // Et surtout PAS une plage de cinq jours : l'axe du rythme en couvre
      // cinq (« un seul jour ne se lit pas seul »), mais les chiffres clés
      // comptent la seule journée. Le libellé décrit ces derniers.
      expect(find.textContaining('5 septembre 2026'), findsOneWidget);
      expect(find.textContaining('1 septembre'), findsNothing);
    });

    testWidgets('l\'année NOMME l\'année, elle n\'invente pas deux bornes', (
      tester,
    ) async {
      // L'année scolaire part de l'ouverture des inscriptions — un fait
      // serveur — et un dossier antidaté peut la faire commencer avant. Le
      // client ne peut donc pas en calculer les bornes ; il nomme l'année.
      final bloc = _blocOn(
        EnrollmentStatsState(
          window: const EnrollmentStatsWindow.year(),
          stats: _statsWithYear('2026-2027'),
          status: EnrollmentStatsStatus.success,
        ),
      );
      addTearDown(bloc.close);
      await _pump(tester, bloc);

      expect(find.text('Année scolaire 2026-2027'), findsOneWidget);
    });

    testWidgets('sans année connue, il dit ce qu\'il sait', (tester) async {
      final bloc = _blocOn(const EnrollmentStatsState());
      addTearDown(bloc.close);
      await _pump(tester, bloc);

      expect(find.text('Depuis l\'ouverture des inscriptions'), findsOneWidget);
    });
  });

  group('la fenêtre libre', () {
    testWidgets('remplace le libellé par ses deux champs', (tester) async {
      final bloc = _blocOn(
        EnrollmentStatsState(
          window: EnrollmentStatsWindow.custom(
            from: DateTime(2026, 5, 18),
            to: DateTime(2026, 5, 24),
          ),
        ),
      );
      addTearDown(bloc.close);
      await _pump(tester, bloc);

      expect(find.byType(EteeloDateInput), findsNWidgets(2));
      expect(find.textContaining('Année scolaire'), findsNothing);
    });

    testWidgets('les bornes se contraignent l\'une l\'autre', (tester) async {
      // Le serveur refuse les bornes inversées en 400 sans les échanger. Mais
      // l'utilisateur n'a pas à découvrir cette règle par une erreur : le
      // sélecteur ne la lui laisse pas composer.
      final bloc = _blocOn(
        EnrollmentStatsState(
          window: EnrollmentStatsWindow.custom(
            from: DateTime(2026, 5, 18),
            to: DateTime(2026, 5, 24),
          ),
        ),
      );
      addTearDown(bloc.close);
      await _pump(tester, bloc);

      final fields = tester
          .widgetList<EteeloDateInput>(find.byType(EteeloDateInput))
          .toList();

      expect(fields[0].lastDate, DateTime(2026, 5, 24));
      expect(fields[1].firstDate, DateTime(2026, 5, 18));
    });
  });

  testWidgets('sur écran étroit, les onglets s\'enroulent sans déborder', (
    tester,
  ) async {
    final bloc = _blocOn(const EnrollmentStatsState());
    addTearDown(bloc.close);
    await _pump(tester, bloc, width: 360);

    expect(tester.takeException(), isNull);
    expect(find.text('Période précise'), findsOneWidget);
  });
}

EnrollmentStats _statsWithYear(String schoolYear) => EnrollmentStats(
  context: StatsContext(
    schoolYear: schoolYear,
    period: 'year',
    periodStart: DateTime.utc(2026, 9, 1),
    periodEnd: DateTime.utc(2027, 6, 30),
    generatedAt: DateTime.utc(2026, 9, 5, 8),
  ),
  headcount: const GenderDistribution(total: 0, segments: <GenderSegment>[]),
  kpis: const EnrollmentKpis(
    totalEnrollments: KpiValue(value: 363),
    firstEnrollments: KpiValue(value: 184),
    reEnrollments: KpiValue(value: 179),
    preEnrollments: KpiValue(value: 0),
    inProgress: KpiValue(value: 0),
  ),
  evolution: const EnrollmentEvolution(
    granularity: EvolutionGranularity.month,
    currentBucketIndex: 0,
    buckets: <EvolutionBucket>[],
  ),
  distributionByCycle: const CycleDistribution(cycles: <CycleStat>[]),
  distributionByGender: const GenderDistribution(
    total: 363,
    segments: <GenderSegment>[],
  ),
);
