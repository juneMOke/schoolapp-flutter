import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_snapshot.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_period.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sale_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/dashboard_period_preference.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_provisional_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_stats_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_dashboard_bloc.dart';

import '../dashboard_fixtures.dart';

class _MockStats extends Mock implements GetBoutiqueStatsUseCase {}

class _MockProvisional extends Mock
    implements GetBoutiqueProvisionalSalesUseCase {}

class _MockPreference extends Mock implements DashboardPeriodPreference {}

void main() {
  late _MockStats getStats;
  late _MockProvisional getProvisional;
  late _MockPreference preference;

  setUpAll(() {
    registerFallbackValue(sevenDays);
    registerFallbackValue(DashboardPeriod.today);
  });

  setUp(() {
    getStats = _MockStats();
    getProvisional = _MockProvisional();
    preference = _MockPreference();
    when(() => preference.read()).thenAnswer((_) async => null);
    when(() => preference.write(any())).thenAnswer((_) async {});
    when(
      () => getStats(
        academicYearId: any(named: 'academicYearId'),
        window: any(named: 'window'),
      ),
    ).thenAnswer(
      (i) async => Right(
        BoutiqueStatsSnapshot(
          stats: statsOf(window: i.namedArguments[#window] as DashboardWindow),
        ),
      ),
    );
    when(
      () => getProvisional(
        academicYearId: any(named: 'academicYearId'),
        window: any(named: 'window'),
      ),
    ).thenAnswer((_) async => const Right(ProvisionalSales.none));
  });

  BoutiqueDashboardBloc build() => BoutiqueDashboardBloc(
    getStats: getStats,
    getProvisional: getProvisional,
    preference: preference,
    now: () => dashboardNow,
  );

  const started = BoutiqueDashboardStarted(academicYearId: 'ay-1');

  blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
    '« Cette semaine » par défaut, du lundi à aujourd\'hui',
    build: build,
    act: (bloc) => bloc.add(started),
    verify: (bloc) {
      expect(bloc.state.status, BoutiqueDashboardStatus.ready);
      expect(bloc.state.period, DashboardPeriod.week);
      expect(bloc.state.window, thisWeek);
      expect(bloc.state.selectedCurrency, 'USD');
    },
  );

  blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
    'la période mémorisée est reprise au montage',
    build: build,
    setUp: () => when(
      () => preference.read(),
    ).thenAnswer((_) async => DashboardPeriod.month),
    act: (bloc) => bloc.add(started),
    verify: (bloc) => expect(bloc.state.window!.from, DateTime(2026, 10)),
  );

  blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
    'changer de période garde les valeurs, atténuées, et mémorise le choix',
    build: build,
    seed: () => BoutiqueDashboardState(
      status: BoutiqueDashboardStatus.ready,
      academicYearId: 'ay-1',
      window: sevenDays,
      stats: statsOf(),
      selectedCurrency: 'USD',
    ),
    act: (bloc) =>
        bloc.add(const BoutiqueDashboardPeriodChanged(DashboardPeriod.today)),
    expect: () => [
      isA<BoutiqueDashboardState>()
          .having((s) => s.period, 'période', DashboardPeriod.today)
          .having((s) => s.refreshing, 'atténué', isFalse),
      isA<BoutiqueDashboardState>()
          .having((s) => s.refreshing, 'atténué', isTrue)
          .having((s) => s.status, 'statut', BoutiqueDashboardStatus.ready)
          .having((s) => s.stats, 'valeurs gardées', isNotNull),
      isA<BoutiqueDashboardState>()
          .having((s) => s.refreshing, 'atténué', isFalse)
          .having((s) => s.stats!.window.isSingleDay, 'un jour', isTrue),
    ],
    verify: (_) =>
        verify(() => preference.write(DashboardPeriod.today)).called(1),
  );

  test('une réponse dépassée par une autre période est jetée', () async {
    final slow = Completer<Either<Failure, BoutiqueStatsSnapshot>>();
    when(
      () => getStats(
        academicYearId: any(named: 'academicYearId'),
        window: thisWeek,
      ),
    ).thenAnswer((_) => slow.future);

    final bloc = build()..add(started);
    await Future<void>.delayed(Duration.zero);
    bloc.add(const BoutiqueDashboardPeriodChanged(DashboardPeriod.today));
    await bloc.stream.firstWhere(
      (s) => s.status == BoutiqueDashboardStatus.ready,
    );
    slow.complete(Right(BoutiqueStatsSnapshot(stats: statsOf())));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.stats!.window.isSingleDay, isTrue);
    await bloc.close();
  });

  blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
    'le serveur en panne : erreur, mais les provisoires restent connus',
    build: build,
    setUp: () {
      when(
        () => getStats(
          academicYearId: any(named: 'academicYearId'),
          window: any(named: 'window'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure('coupure')));
      when(
        () => getProvisional(
          academicYearId: any(named: 'academicYearId'),
          window: any(named: 'window'),
        ),
      ).thenAnswer(
        (_) async => Right(
          ProvisionalSales([
            ProvisionalSaleLine(
              saleId: 'p-1',
              soldAt: dashboardNow,
              currency: 'USD',
              lineTotal: 4700,
              quantity: 1,
            ),
          ]),
        ),
      );
    },
    act: (bloc) => bloc.add(started),
    verify: (bloc) {
      expect(bloc.state.status, BoutiqueDashboardStatus.failure);
      expect(bloc.state.failure, isA<NetworkFailure>());
      expect(bloc.state.provisional.saleCount, 1);
    },
  );

  blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
    'les provisoires se lisent sur la fenêtre de la PHOTO, pas sur la demandée',
    build: build,
    setUp: () =>
        when(
          () => getStats(
            academicYearId: any(named: 'academicYearId'),
            window: any(named: 'window'),
          ),
        ).thenAnswer(
          (_) async => Right(
            BoutiqueStatsSnapshot(
              stats: statsOf(
                window: DashboardWindow(
                  from: DateTime(2026, 10, 14),
                  to: DateTime(2026, 10, 20),
                ),
              ),
              cachedAt: DateTime(2026, 10, 20, 9),
            ),
          ),
        ),
    act: (bloc) => bloc.add(started),
    verify: (bloc) {
      verify(
        () => getProvisional(
          academicYearId: 'ay-1',
          window: DashboardWindow(
            from: DateTime(2026, 10, 14),
            to: DateTime(2026, 10, 20),
          ),
        ),
      ).called(1);
      expect(bloc.state.cachedAt, DateTime(2026, 10, 20, 9));
    },
  );

  blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
    'la devise examinée survit si la réponse la porte encore',
    build: build,
    seed: () => const BoutiqueDashboardState(
      academicYearId: 'ay-1',
      selectedCurrency: 'CDF',
    ),
    setUp: () =>
        when(
          () => getStats(
            academicYearId: any(named: 'academicYearId'),
            window: any(named: 'window'),
          ),
        ).thenAnswer(
          (_) async => Right(
            BoutiqueStatsSnapshot(stats: statsOf(currencies: ['CDF', 'USD'])),
          ),
        ),
    act: (bloc) => bloc.add(const BoutiqueDashboardRefreshRequested()),
    verify: (bloc) => expect(bloc.state.selectedCurrency, 'CDF'),
  );

  test('une devise que la réponse ne porte pas est ignorée', () async {
    final bloc = build()..add(started);
    await bloc.stream.firstWhere((s) => s.stats != null);
    bloc.add(const BoutiqueDashboardCurrencySelected('EUR'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCurrency, 'USD');
    await bloc.close();
  });

  test('un second démarrage pour la même année ne relit rien', () async {
    final bloc = build()
      ..add(started)
      ..add(started);
    await bloc.stream.firstWhere(
      (s) => s.status == BoutiqueDashboardStatus.ready,
    );
    await Future<void>.delayed(Duration.zero);
    verify(
      () => getStats(
        academicYearId: any(named: 'academicYearId'),
        window: any(named: 'window'),
      ),
    ).called(1);
    await bloc.close();
  });

  test('un geste de période avant la première fenêtre est ignoré', () async {
    final bloc = build()
      ..add(const BoutiqueDashboardPeriodChanged(DashboardPeriod.today));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.period, DashboardPeriod.week);
    verifyNever(() => preference.write(any()));
    await bloc.close();
  });

  blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
    'actualiser recalcule la fenêtre : minuit passé, l\'écran suit',
    build: () => BoutiqueDashboardBloc(
      getStats: getStats,
      getProvisional: getProvisional,
      preference: preference,
      // 0 h 10 le 22 à Kinshasa.
      now: () => DateTime.utc(2026, 10, 21, 23, 10),
    ),
    seed: () => BoutiqueDashboardState(
      status: BoutiqueDashboardStatus.ready,
      academicYearId: 'ay-1',
      window: sevenDays,
      stats: statsOf(),
    ),
    act: (bloc) => bloc.add(const BoutiqueDashboardRefreshRequested()),
    verify: (bloc) => expect(bloc.state.window!.to, DateTime(2026, 10, 22)),
  );

  blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
    '« Année » part de l\'ouverture de l\'année scolaire',
    build: build,
    seed: () => BoutiqueDashboardState(
      status: BoutiqueDashboardStatus.ready,
      academicYearId: 'ay-1',
      yearStart: DateTime(2026, 9),
      window: thisWeek,
      stats: statsOf(window: thisWeek),
    ),
    act: (bloc) =>
        bloc.add(const BoutiqueDashboardPeriodChanged(DashboardPeriod.year)),
    verify: (bloc) {
      expect(bloc.state.window!.from, DateTime(2026, 9));
      expect(bloc.state.window!.to, DateTime(2026, 10, 21));
      verify(() => preference.write(DashboardPeriod.year)).called(1);
    },
  );

  group('période précise', () {
    final range = DashboardWindow(
      from: DateTime(2026, 10, 5),
      to: DateTime(2026, 10, 9),
    );

    BoutiqueDashboardState seeded() => BoutiqueDashboardState(
      status: BoutiqueDashboardStatus.ready,
      academicYearId: 'ay-1',
      window: thisWeek,
      stats: statsOf(window: thisWeek),
    );

    blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
      'l\'onglet ouvre sur la journée du jour, sans être mémorisé',
      build: build,
      seed: seeded,
      act: (bloc) => bloc.add(
        const BoutiqueDashboardPeriodChanged(DashboardPeriod.custom),
      ),
      verify: (bloc) {
        expect(bloc.state.period, DashboardPeriod.custom);
        expect(
          bloc.state.window,
          DashboardWindow(
            from: DateTime(2026, 10, 21),
            to: DateTime(2026, 10, 21),
          ),
        );
        verifyNever(() => preference.write(any()));
      },
    );

    blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
      'les bornes saisies sont lues telles quelles',
      build: build,
      seed: seeded,
      act: (bloc) => bloc.add(BoutiqueDashboardCustomRangeChanged(range)),
      verify: (bloc) {
        expect(bloc.state.period, DashboardPeriod.custom);
        expect(bloc.state.window, range);
        expect(bloc.state.stats!.window, range);
        verify(() => getStats(academicYearId: 'ay-1', window: range)).called(1);
      },
    );

    blocTest<BoutiqueDashboardBloc, BoutiqueDashboardState>(
      'actualiser rejoue les bornes saisies, sans les recalculer',
      build: build,
      seed: () =>
          seeded().copyWith(period: DashboardPeriod.custom, window: range),
      act: (bloc) => bloc.add(const BoutiqueDashboardRefreshRequested()),
      verify: (bloc) => expect(bloc.state.window, range),
    );
  });

  group('isDeltaComparable', () {
    test(
      'une fenêtre précédente qui chevauche la rentrée ne se compare pas',
      () {
        final state = BoutiqueDashboardState(
          stats: statsOf(),
          // Fenêtre précédente : du 8 au 14 ; rentrée le 10.
          yearStart: DateTime(2026, 10, 10),
        );
        expect(state.isDeltaComparable, isFalse);
      },
    );

    test('après la rentrée, elle se compare', () {
      final state = BoutiqueDashboardState(
        stats: statsOf(),
        yearStart: DateTime(2026, 9, 1),
      );
      expect(state.isDeltaComparable, isTrue);
    });
  });
}
