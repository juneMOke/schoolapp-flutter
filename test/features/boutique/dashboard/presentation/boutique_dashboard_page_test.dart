import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
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
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sale_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/dashboard_period_preference.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_beneficiaries_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_catalog_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_provisional_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_stats_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/claim_sale_receipt_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/mark_sale_ticket_printed_use_case.dart';
import 'package:school_app_flutter/router/boutique_sale_routes.dart';
import 'package:school_app_flutter/router/reflected_records_parser.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_dashboard_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_report_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_dashboard_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_dashboard_location.dart';
import 'package:school_app_flutter/core/components/tables/data_table_view.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/reference_formats.dart';

import '../dashboard_fixtures.dart';

class _MockStats extends Mock implements GetBoutiqueStatsUseCase {}

class _MockProvisional extends Mock
    implements GetBoutiqueProvisionalSalesUseCase {}

class _MockSales extends Mock implements GetBoutiqueSalesUseCase {}

class _MockSalesReport extends Mock implements GetBoutiqueSalesReportUseCase {}

class _MockBeneficiaries extends Mock
    implements GetBoutiqueBeneficiariesUseCase {}

class _MockCatalog extends Mock implements GetBoutiqueCatalogUseCase {}

class _MockPreference extends Mock implements DashboardPeriodPreference {}

class _MockSaleDetail extends Mock implements GetBoutiqueSaleDetailUseCase {}

class _MockMarkPrinted extends Mock implements MarkSaleTicketPrintedUseCase {}

class _MockClaimReceipt extends Mock implements ClaimSaleReceiptUseCase {}

class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockNavigationBloc extends MockBloc<NavigationEvent, NavigationState>
    implements NavigationBloc {}

void main() {
  late _MockStats getStats;
  late _MockProvisional getProvisional;
  late _MockBeneficiaries getBeneficiaries;
  late _MockSales getSales;
  late _MockAcademicYearBloc academicYearBloc;
  late _MockAuthBloc authBloc;
  final queries = <BeneficiariesQuery>[];
  final salesQueries = <SalesQuery>[];
  final statsWindows = <DashboardWindow>[];
  GoRouter? router;

  setUpAll(() {
    registerFallbackValue(sevenDays);
    registerFallbackValue(DashboardPeriod.today);
    registerFallbackValue(
      BeneficiariesQuery(academicYearId: '', window: sevenDays),
    );
    registerFallbackValue(SalesQuery(academicYearId: '', window: sevenDays));
    registerFallbackValue(
      const SubMenuItemSelected(menuId: '', subMenuId: '', title: ''),
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
      ).thenAnswer((i) async {
        final window = i.namedArguments[#window] as DashboardWindow;
        statsWindows.add(window);
        return answer(window);
      });

  setUp(() {
    queries.clear();
    salesQueries.clear();
    statsWindows.clear();
    router = null;
    getStats = _MockStats();
    getProvisional = _MockProvisional();
    getBeneficiaries = _MockBeneficiaries();
    getSales = _MockSales();
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
    when(() => getSales(any())).thenAnswer((i) async {
      salesQueries.add(i.positionalArguments.first as SalesQuery);
      return Right(salesPageOf(total: 30));
    });
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
      )
      ..registerFactory<BoutiqueSalesCubit>(
        () => BoutiqueSalesCubit(getSales: getSales),
      )
      ..registerFactory<BoutiqueSalesReportCubit>(
        () => BoutiqueSalesReportCubit(getReport: _MockSalesReport()),
      );
  });

  tearDown(() => GetIt.I.reset());

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(1280, 2600),
    ReferenceFormat? format,
    NavigationBloc? navigation,
    String? location,
  }) async {
    // Un format de référence pose la fenêtre (et `MediaQuery`) ; sans lui,
    // une grande surface où tout le tableau de bord se construit.
    if (format == null) {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    final providers = [
      BlocProvider<AcademicYearContextBloc>.value(value: academicYearBloc),
      BlocProvider<AuthBloc>.value(value: authBloc),
      if (navigation != null)
        BlocProvider<NavigationBloc>.value(value: navigation),
    ];
    if (location == null) {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: providers,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: BoutiqueDashboardPage(),
          ),
        ),
      );
    } else {
      // Un F5 : l'arbre est rebâti à neuf depuis la seule adresse.
      final next = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: '/home/:subMenuId',
            builder: (_, _) => const BoutiqueDashboardPage(),
            routes: [BoutiqueSaleRoutes.sale()],
          ),
        ],
      );
      addTearDown(next.dispose);
      router = next;
      await tester.pumpWidget(
        MultiBlocProvider(
          key: UniqueKey(),
          providers: providers,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            routerConfig: ReflectedRecordsParser.configOf(next),
          ),
        ),
      );
    }
    await tester.pumpAndSettle();
  }

  /// L'adresse de la barre du navigateur, fiche poussée comprise.
  String address() => router!.routeInformationProvider.value.uri.toString();

  BoutiqueDashboardState dashboardState(WidgetTester tester) => tester
      .element(find.byType(BoutiqueDashboardLocation))
      .read<BoutiqueDashboardBloc>()
      .state;

  group('l\'adresse', () {
    const base = '/home/${MenuConstants.boutiqueDashboardId}';

    testWidgets('période, filtres et page s\'inscrivent ; F5 les restitue', (
      tester,
    ) async {
      await pumpPage(tester, location: base);
      expect(address(), base);

      await tester.tap(find.text('Aujourd\'hui'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1. Polo Lacoste'));
      await tester.pumpAndSettle();
      final sales = tester
          .element(find.byType(BoutiqueDashboardLocation))
          .read<BoutiqueSalesCubit>();
      await sales.classSelected('c-5b');
      await tester.pumpAndSettle();
      await sales.pageChanged(1);
      await tester.pumpAndSettle();

      final written = Uri.parse(address());
      expect(written.queryParameters, {
        'periode': 'today',
        'ventes-par': 'classe',
        'ventes-classe': 'c-5b',
        'ventes-page': '2',
        'eleves-article': 'a-polo',
      });

      // F5 : tout est relu depuis la seule adresse.
      statsWindows.clear();
      salesQueries.clear();
      queries.clear();
      await pumpPage(tester, location: written.toString());

      expect(statsWindows.single.isSingleDay, isTrue);
      expect(dashboardState(tester).period, DashboardPeriod.today);
      expect(salesQueries.single.classId, 'c-5b');
      expect(salesQueries.single.page, 1);
      expect(queries.last.articleId, 'a-polo');
      expect(Uri.parse(address()).queryParameters, written.queryParameters);
    });

    testWidgets('une période précise et sa devise se rouvrent par lien', (
      tester,
    ) async {
      answerStats(
        (w) => Right(
          BoutiqueStatsSnapshot(
            stats: statsOf(window: w, currencies: const ['USD', 'CDF']),
          ),
        ),
      );
      await pumpPage(
        tester,
        location: '$base?periode=custom&du=2026-10-12&au=2026-10-05&devise=CDF',
      );

      expect(
        statsWindows.single,
        DashboardWindow(
          from: DateTime(2026, 10, 5),
          to: DateTime(2026, 10, 12),
        ),
      );
      expect(dashboardState(tester).selectedCurrency, 'CDF');
      expect(Uri.parse(address()).queryParameters, {
        'periode': 'custom',
        'du': '2026-10-05',
        'au': '2026-10-12',
        'devise': 'CDF',
      });
    });

    testWidgets(
      'contre-épreuve : une adresse nue garde la période par défaut',
      (tester) async {
        await pumpPage(tester, location: base);
        expect(statsWindows.single, thisWeek);
        expect(salesQueries.single.page, 0);
        expect(address(), base);
      },
    );

    testWidgets('une vente s\'ouvre à son adresse, filtres du dessous gardés', (
      tester,
    ) async {
      final getDetail = _MockSaleDetail();
      when(
        () => getDetail(any()),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));
      GetIt.I
        ..registerFactory<GetBoutiqueSaleDetailUseCase>(() => getDetail)
        ..registerFactory<MarkSaleTicketPrintedUseCase>(_MockMarkPrinted.new)
        ..registerFactory<ClaimSaleReceiptUseCase>(_MockClaimReceipt.new);
      await pumpPage(tester, location: '$base?periode=today');

      await tester.tap(find.text('RV-000472').first);
      await tester.pumpAndSettle();

      expect(address(), '$base/vente/s-0-1?periode=today');
      verify(() => getDetail('s-0-1')).called(1);
      // Le tableau de bord du dessous n'a pas lu l'adresse de la fiche comme
      // un retour à « Cette semaine ».
      expect(statsWindows.every((w) => w.isSingleDay), isTrue);

      await tester.tap(find.byTooltip('Retour au tableau de bord'));
      await tester.pumpAndSettle();
      expect(address(), '$base?periode=today');
    });
  });

  testWidgets('prêt : chiffres, temps, contenu, élèves, reçus', (tester) async {
    await pumpPage(tester);

    expect(find.text('RECETTES'), findsOneWidget);
    expect(find.text('PANIER MOYEN'), findsOneWidget);
    expect(find.text('Recettes jour par jour'), findsOneWidget);
    expect(find.text('Par famille'), findsOneWidget);
    expect(find.text('Articles les plus vendus'), findsOneWidget);
    expect(find.text('Élèves concernés'), findsOneWidget);
    // Deux tableaux à la manière de la caisse : ventes, élèves.
    expect(find.byType(DataTableView), findsNWidgets(2));
    expect(find.text('Ventes de la période'), findsOneWidget);
    expect(find.text('ÉLÈVE(S)'), findsOneWidget);
    // Les élèves de la vente, pas son payeur ; à défaut, le payeur marqué ;
    // sans personne, la vente se dit anonyme.
    expect(find.text('KABONGO Daniel, KABONGO Ruth'), findsOneWidget);
    expect(find.text('Payeur : MBUYI Grâce'), findsOneWidget);
    expect(find.text('Vente anonyme'), findsOneWidget);
    expect(find.text('Télécharger le PDF'), findsOneWidget);
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

  testWidgets(
    'hors ligne : les chiffres de la photo, les ventes en erreur réseau',
    (tester) async {
      // Pas de cache pour la liste : seuls les chiffres ont une photo datée.
      answerStats(
        (w) => Right(
          BoutiqueStatsSnapshot(
            stats: statsOf(window: w),
            cachedAt: DateTime(2026, 10, 20, 18, 5),
          ),
        ),
      );
      when(
        () => getSales(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('coupure')));
      await pumpPage(tester);

      expect(
        find.textContaining('Hors ligne — chiffres du 20/10/2026'),
        findsOneWidget,
      );
      expect(find.text('RV-000472'), findsNothing);
      // Une seule erreur : celle de la liste, les chiffres sont servis.
      expect(find.text('Réessayer'), findsOneWidget);

      clearInteractions(getSales);
      when(() => getSales(any())).thenAnswer((_) async => Right(salesPageOf()));
      await tester.ensureVisible(find.text('Réessayer'));
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      final query =
          verify(() => getSales(captureAny())).captured.single as SalesQuery;
      expect(query.page, 0);
      expect(find.text('RV-000472'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    },
  );

  testWidgets('F5 relit les chiffres et les deux listes, sans recharger', (
    tester,
  ) async {
    await pumpPage(tester);
    final stats = statsWindows.length;
    final sales = salesQueries.length;
    final pupils = queries.length;

    final handled = await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(statsWindows.length, stats + 1);
    expect(salesQueries.length, sales + 1);
    expect(queries.length, pupils + 1);
  });

  testAtReferenceFormats('le tableau de bord tient', (tester, format) async {
    await pumpPage(tester, format: format);
    await tester.scrollUntilVisible(
      find.text('Élèves concernés'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Élèves concernés'), findsOneWidget);
  });

  testWidgets('« Ouvrir la caisse » passe au sous-menu, dans la coquille', (
    tester,
  ) async {
    final navigation = _MockNavigationBloc();
    when(() => navigation.state).thenReturn(
      const NavigationState(
        menuItems: [],
        isSidebarExpanded: true,
        currentTitle: '',
      ),
    );
    await pumpPage(tester, navigation: navigation);

    await tester.tap(find.text('Ouvrir la caisse'));
    await tester.pump();

    // Une route nue (`context.go`) perdrait la barre latérale et le retour.
    final event =
        verify(() => navigation.add(captureAny())).captured.single
            as SubMenuItemSelected;
    expect(event.menuId, MenuConstants.boutiqueMenuId);
    expect(event.subMenuId, MenuConstants.boutiqueAchatsId);
    expect(event.title, 'Caisse');
  });
}
