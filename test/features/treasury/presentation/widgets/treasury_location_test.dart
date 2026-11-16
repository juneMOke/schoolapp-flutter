import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_pending_probe.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_reports_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_screen.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_location_sync.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

class _DayRepository extends Mock implements TreasuryDayRepository {}

class _ReportsRepository extends Mock implements TreasuryReportsRepository {}

class _Probe extends Mock implements CashPendingProbe {}

/// Les écrans de la trésorerie tiennent leur état dans l'adresse : F5 rouvre
/// la même journée, la même vue, la même page de rapports.
void main() {
  late GoRouter router;
  late _DayRepository days;

  setUpAll(() {
    registerFallbackValue(TreasuryCurrency.usd);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CashReportKind.daily);
  });

  setUp(() {
    days = _DayRepository();
    when(() => days.day(any())).thenAnswer(
      (invocation) async => Right(
        treasuryDay([
          usdDay(),
          cdfDay(),
        ], date: invocation.positionalArguments.first as DateTime),
      ),
    );
    when(
      () => days.period(any(), any()),
    ).thenAnswer((_) async => Right(treasuryWeek()));
    GetIt.instance.registerSingleton<TreasuryDayRepository>(days);
  });

  tearDown(() => GetIt.instance.unregister<TreasuryDayRepository>());

  Future<void> pump(WidgetTester tester, String location, Widget page) async {
    setTestWindow(tester, const Size(1280, 1400));
    router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/tresorerie/:id',
          builder: (_, _) => Scaffold(body: SingleChildScrollView(child: page)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String address() => router.routerDelegate.currentConfiguration.uri.toString();

  Widget closing() {
    final probe = _Probe();
    when(() => probe.pendingFor(any())).thenAnswer((_) async => 0);
    return BlocProvider(
      create: (_) =>
          CashClosingCubit(days, probe, initialDate: demoDay)..load(),
      child: const ClosingScreen(online: true, callbacks: ClosingCallbacks()),
    );
  }

  group('Clôture', () {
    testWidgets('aujourd hui : l adresse reste nue', (tester) async {
      await pump(tester, '/tresorerie/cloture', closing());
      expect(address(), '/tresorerie/cloture');
    });

    testWidgets('la veille s inscrit dans l adresse', (tester) async {
      await pump(tester, '/tresorerie/cloture', closing());
      await tester.tap(find.byTooltip('Journée précédente'));
      await tester.pumpAndSettle();
      expect(address(), '/tresorerie/cloture?jour=2026-10-21');
    });

    testWidgets('F5 : l adresse rouvre la journée demandée', (tester) async {
      await pump(tester, '/tresorerie/cloture?jour=2026-10-20', closing());
      expect(find.text('Mardi 20 octobre 2026'), findsOneWidget);
      verify(() => days.day(DateTime(2026, 10, 20))).called(1);
    });

    testWidgets('F5 : l adresse rouvre la semaine', (tester) async {
      await pump(tester, '/tresorerie/cloture?vue=semaine', closing());
      verify(() => days.period(any(), any())).called(1);
      expect(address(), '/tresorerie/cloture?vue=semaine');
    });

    testWidgets('la semaine précédente garde son début dans l adresse', (
      tester,
    ) async {
      await pump(tester, '/tresorerie/cloture?vue=semaine', closing());
      await tester.tap(find.byTooltip('Période précédente'));
      await tester.pumpAndSettle();
      expect(address(), '/tresorerie/cloture?vue=semaine&debut=2026-10-12');
    });
  });

  group('Rapports', () {
    late _ReportsRepository reports;

    setUp(() {
      reports = _ReportsRepository();
      when(() => reports.list(any(), any())).thenAnswer(
        (_) async => Right(
          CashReportPage(items: [cashReport()], number: 0, totalPages: 3),
        ),
      );
    });

    Widget panel() => BlocProvider(
      create: (_) => CashReportsCubit(reports, today: demoDay)..load(),
      child: const ReportsLocationSync(child: SizedBox()),
    );

    testWidgets('F5 : le type et la page reviennent, en une lecture', (
      tester,
    ) async {
      await pump(
        tester,
        '/tresorerie/tableau?rapports=weekly&rapports-page=2',
        panel(),
      );
      verify(() => reports.list(CashReportKind.weekly, 1)).called(1);
      expect(address(), '/tresorerie/tableau?rapports=weekly&rapports-page=2');
    });

    testWidgets('F5 sur la page 3 des journaliers : la page reste demandée', (
      tester,
    ) async {
      late CashReportsCubit cubit;
      await pump(
        tester,
        '/tresorerie/tableau?rapports-page=3',
        BlocProvider(
          create: (_) =>
              cubit = CashReportsCubit(reports, today: demoDay)..load(),
          child: const ReportsLocationSync(child: SizedBox()),
        ),
      );
      verify(() => reports.list(CashReportKind.daily, 2)).called(1);
      // Réessayer relit `requestedPage` : la page de l'adresse.
      expect(cubit.state.requestedPage, 2);
      expect(address(), '/tresorerie/tableau?rapports-page=3');
    });

    testWidgets('contre-épreuve : une adresse nue garde les journaliers', (
      tester,
    ) async {
      await pump(tester, '/tresorerie/tableau', panel());
      verifyNever(() => reports.list(CashReportKind.weekly, any()));
      expect(address(), '/tresorerie/tableau');
    });
  });
}
