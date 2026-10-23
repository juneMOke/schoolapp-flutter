import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiaries_query.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_snapshot.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_period.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sale_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/dashboard_period_preference.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_beneficiaries_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_catalog_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_latest_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_provisional_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_stats_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_dashboard_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_dashboard_page.dart';
import 'package:school_app_flutter/core/components/tables/data_table_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../dashboard_fixtures.dart';

class _MockStats extends Mock implements GetBoutiqueStatsUseCase {}

class _MockProvisional extends Mock
    implements GetBoutiqueProvisionalSalesUseCase {}

class _MockLatest extends Mock implements GetBoutiqueLatestSalesUseCase {}

class _MockBeneficiaries extends Mock
    implements GetBoutiqueBeneficiariesUseCase {}

class _MockCatalog extends Mock implements GetBoutiqueCatalogUseCase {}

class _MockPreference extends Mock implements DashboardPeriodPreference {}

class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockStats getStats;
  late _MockProvisional getProvisional;
  late _MockBeneficiaries getBeneficiaries;
  late _MockAcademicYearBloc academicYearBloc;
  late _MockAuthBloc authBloc;
  final queries = <BeneficiariesQuery>[];

  setUpAll(() {
    registerFallbackValue(sevenDays);
    registerFallbackValue(DashboardPeriod.today);
    registerFallbackValue(
      BeneficiariesQuery(academicYearId: '', window: sevenDays),
    );
  });

  void answerStats(
    Either<Failure, BoutiqueStatsSnapshot> Function(DashboardWindow) answer,
  ) =>
      when(
        () => getStats(
          academicYearId: any(named: 'academicYearId'),
          window: any(named: 'window'),
        ),
      ).thenAnswer(
        (i) async => answer(i.namedArguments[#window] as DashboardWindow),
      );

  setUp(() {
    queries.clear();
    getStats = _MockStats();
    getProvisional = _MockProvisional();
    getBeneficiaries = _MockBeneficiaries();
    final getLatest = _MockLatest();
    final getCatalog = _MockCatalog();
    final preference = _MockPreference();
    academicYearBloc = _MockAcademicYearBloc();
    authBloc = _MockAuthBloc();

    when(() => academicYearBloc.state).thenReturn(
      const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: AcademicYearContext(
          academicYear: AcademicYear(
            id: 'ay-1',
            name: '2026-2027',
            current: true,
          ),
          schoolLevelGroups: [],
        ),
      ),
    );
    when(
      () => authBloc.state,
    ).thenReturn(const AuthState(status: AuthStatus.authenticated));
    when(() => preference.read()).thenAnswer((_) async => null);
    when(() => preference.write(any())).thenAnswer((_) async {});
    answerStats((w) => Right(BoutiqueStatsSnapshot(stats: statsOf(window: w))));
    when(
      () => getProvisional(
        academicYearId: any(named: 'academicYearId'),
        window: any(named: 'window'),
      ),
    ).thenAnswer((_) async => const Right(ProvisionalSales.none));
    when(
      () => getLatest(
        academicYearId: any(named: 'academicYearId'),
        window: any(named: 'window'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => Right([saleEntry('s-1'), saleEntry('s-2')]));
    when(() => getBeneficiaries(any())).thenAnswer((i) async {
      queries.add(i.positionalArguments.first as BeneficiariesQuery);
      return Right(beneficiariesOf());
    });
    when(() => getCatalog(any())).thenAnswer(
      (_) async => const Right(BoutiqueCatalog(articles: [], withheld: false)),
    );

    GetIt.I
      ..registerFactory<BoutiqueDashboardBloc>(
        () => BoutiqueDashboardBloc(
          getStats: getStats,
          getProvisional: getProvisional,
          getLatest: getLatest,
          preference: preference,
          now: () => dashboardNow,
        ),
      )
      ..registerFactory<BoutiqueBeneficiariesCubit>(
        () => BoutiqueBeneficiariesCubit(
          getBeneficiaries: getBeneficiaries,
          getCatalog: getCatalog,
          debounce: Duration.zero,
        ),
      );
  });

  tearDown(() => GetIt.I.reset());

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(1280, 2600),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AcademicYearContextBloc>.value(value: academicYearBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: BoutiqueDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prêt : chiffres, temps, contenu, élèves, reçus', (tester) async {
    await pumpPage(tester);

    expect(find.text('RECETTES'), findsOneWidget);
    expect(find.text('PANIER MOYEN'), findsOneWidget);
    expect(find.text('Recettes jour par jour'), findsOneWidget);
    expect(find.text('Par famille'), findsOneWidget);
    expect(find.text('Articles les plus vendus'), findsOneWidget);
    expect(find.text('Élèves concernés'), findsOneWidget);
    // Deux tableaux à la manière de la caisse : dernières ventes, élèves.
    expect(find.byType(DataTableView), findsNWidgets(2));
    expect(find.text('PAYEUR'), findsOneWidget);
    expect(find.text('DERNIER ACHAT'), findsOneWidget);
    expect(find.textContaining('du 19/10/2026 au 21/10/2026'), findsOneWidget);
    // Le delta : 61 ventes contre 55.
    expect(find.text('+11 % vs période précédente'), findsOneWidget);
    expect(queries.single.window, thisWeek);
  });

  testWidgets('un article du palmarès filtre la liste des élèves', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('1. Polo Lacoste'));
    await tester.pumpAndSettle();
    expect(queries.last.articleId, 'a-polo');
    expect(find.textContaining('Ont reçu « Polo Lacoste »'), findsOneWidget);
  });

  testWidgets('« Aujourd\'hui » relit une seule journée, liste comprise', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Aujourd\'hui'));
    await tester.pumpAndSettle();
    expect(find.text('Recettes heure par heure'), findsOneWidget);
    expect(queries.last.window.isSingleDay, isTrue);
  });

  testWidgets('les quatre chiffres clés sont des pavés, flèche comprise', (
    tester,
  ) async {
    await pumpPage(tester);
    final cards = tester.widgetList<EteeloKpiCard>(find.byType(EteeloKpiCard));
    expect(cards, hasLength(4));
    expect(cards.every((c) => c.data.isFilled), isTrue);
    // Ventes 61/55, articles 97/88, recettes 1 284/1 102 en une devise.
    expect(find.byIcon(Icons.trending_up_rounded), findsAtLeastNWidgets(3));
    expect(
      find.text('Pas de période comparable avant la rentrée'),
      findsNothing,
    );
  });

  testWidgets('les cinq périodes des inscriptions, dans le même ordre', (
    tester,
  ) async {
    await pumpPage(tester);
    for (final label in [
      'Aujourd\'hui',
      'Cette semaine',
      'Ce mois',
      'Année',
      'Période précise',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('7 jours'), findsNothing);
    expect(find.text('30 jours'), findsNothing);
  });

  testWidgets('« Période précise » ouvre ses bornes sur la journée du jour', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.byType(EteeloDateInput), findsNothing);
    await tester.tap(find.text('Période précise'));
    await tester.pumpAndSettle();
    expect(find.byType(EteeloDateInput), findsNWidgets(2));
    expect(
      queries.last.window,
      DashboardWindow(from: DateTime(2026, 10, 21), to: DateTime(2026, 10, 21)),
    );
    expect(
      find.textContaining('Ventes au comptant du 21/10/2026'),
      findsOneWidget,
    );
  });

  testWidgets('rien vendu : l\'état vide invite à élargir, la période reste', (
    tester,
  ) async {
    answerStats(
      (w) => Right(
        BoutiqueStatsSnapshot(
          stats: statsOf(window: w, saleCount: 0, currencies: const []),
        ),
      ),
    );
    await pumpPage(tester);
    expect(find.text('Aucune vente sur 3 jours'), findsOneWidget);
    expect(find.text('Cette semaine'), findsOneWidget);
    expect(find.text('Élèves concernés'), findsNothing);
  });

  testWidgets('403 : aucune proposition de réessayer', (tester) async {
    answerStats((_) => const Left(UnauthorizedFailure()));
    await pumpPage(tester);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets(
    'coupure : erreur réseau, et l\'encart des provisoires au-dessus',
    (tester) async {
      answerStats((_) => const Left(NetworkFailure('coupure')));
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
      await pumpPage(tester);
      expect(find.textContaining('1 ticket provisoire'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    },
  );

  testWidgets('photo hors ligne : datée dans l\'en-tête', (tester) async {
    answerStats(
      (w) => Right(
        BoutiqueStatsSnapshot(
          stats: statsOf(window: w),
          cachedAt: DateTime(2026, 10, 20, 18, 5),
        ),
      ),
    );
    await pumpPage(tester);
    expect(
      find.textContaining('Hors ligne — chiffres du 20/10/2026'),
      findsOneWidget,
    );
  });

  testWidgets('largeur téléphone : aucun débordement', (tester) async {
    await pumpPage(tester, size: const Size(360, 4200));
    expect(tester.takeException(), isNull);
    expect(find.text('Élèves concernés'), findsOneWidget);
  });
}
