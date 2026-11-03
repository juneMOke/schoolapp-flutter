import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/payroll/data/dashboard/payroll_dashboard_json.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_dashboard_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_dashboard_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_advances_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_dashboard_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_settings_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_advance_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_refresh_shortcut.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/advances/payroll_advances_location.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_location.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_month_location.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/reflected_records_parser.dart';

import '../../staff/staff_builders.dart';
import '../data/payroll_dashboard_json_test.dart' show payrollDashboardFixture;
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

class _MockDashboards extends Mock implements PayrollDashboardRepository {}

class _MockPayslips extends Mock implements PayslipRepository {}

class _MockSignals extends Mock implements StaffSyncSignals {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Les filtres de RH · Paie tenus dans l'adresse : écrits au geste, rendus
/// par un F5 (un écran rebâti à neuf depuis la seule adresse).
void main() {
  PayrollSnapshot snapshot() => PayrollSnapshot(
    members: [
      member('m-1', lastName: 'Mayala', firstName: 'Ruth'),
      member('m-2', lastName: 'Kabeya', firstName: 'Jean'),
    ],
    contractsByMember: {
      'm-1': [contract('m-1', from: '2026-06-01')],
      'm-2': [
        contract('m-2', from: '2026-06-01', kind: StaffContractKind.vacataire),
      ],
    },
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: {
      '2026-09': const PayrollHeader(
        id: 'p-09',
        month: '2026-09',
        status: PayrollStatus.validated,
        validationGestureId: 'g-v',
      ),
    },
    variables: const {},
    frozenLines: {
      '2026-09': [frozenLine('m-1', '2026-09'), frozenLine('m-2', '2026-09')],
    },
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: const [],
    schoolYears: const [(start: '2026-09-07', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
  );

  Future<void> wide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('le livre', () {
    testWidgets('contrat et versement s\'inscrivent ; F5 les restitue', (
      tester,
    ) async {
      await wide(tester);
      late GoRouter router;
      Uri address() => router.routeInformationProvider.value.uri;
      await pumpPayrollScreen(
        tester,
        snapshot: snapshot(),
        location: '/home/paie?mois=2026-09',
        child: const PayrollMonthLocation(child: PayrollScreen()),
        onRouter: (r) => router = r,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Permanent').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Non payés').first);
      await tester.pumpAndSettle();

      final written = address();
      expect(written.queryParameters, {
        'mois': '2026-09',
        'contrat': 'permanent',
        'versement': 'unpaid',
      });

      final reopened = await pumpPayrollScreen(
        tester,
        snapshot: snapshot(),
        location: written.toString(),
        child: const PayrollMonthLocation(child: PayrollScreen()),
        onRouter: (r) => router = r,
      );
      await tester.pumpAndSettle();

      expect(reopened.cubit.state.month, '2026-09');
      expect(reopened.cubit.state.contractFilter, StaffContractKind.permanent);
      expect(reopened.cubit.state.payFilter, PayrollPayFilter.unpaid);
      expect(address().queryParameters, written.queryParameters);
    });
  });

  group('la fiche ouverte depuis le livre', () {
    testWidgets('son adresse garde les filtres du livre : le retour après F5 '
        'retrouve le même livre', (tester) async {
      await wide(tester);
      late GoRouter router;
      Uri address() => router.routeInformationProvider.value.uri;
      await pumpPayrollScreen(
        tester,
        snapshot: snapshot(),
        location: '/home/paie?mois=2026-09&versement=unpaid',
        child: const PayrollMonthLocation(child: PayrollScreen()),
        onRouter: (r) => router = r,
      );
      await tester.pumpAndSettle();

      final eye = find.byTooltip("Ouvrir la fiche de l'agent").first;
      await tester.ensureVisible(eye);
      await tester.tap(eye);
      await tester.pumpAndSettle();

      expect(address().path, startsWith('/home/paie/m-'));
      expect(address().queryParameters, {
        'mois': '2026-09',
        'versement': 'unpaid',
        'mois-agent': '2026-09',
      });
    });
  });

  group('les avances', () {
    testWidgets('le filtre s\'inscrit ; F5 le restitue ; « En cours » est '
        'l\'adresse nue', (tester) async {
      await wide(tester);
      late GoRouter router;
      Uri address() => router.routeInformationProvider.value.uri;
      const screen = PayrollAdvancesLocation(child: PayrollAdvancesScreen());
      await pumpPayrollScreen(
        tester,
        snapshot: snapshot(),
        location: '/home/paie-avances',
        child: screen,
        onRouter: (r) => router = r,
      );
      await tester.pumpAndSettle();
      expect(address().toString(), '/home/paie-avances');

      await tester.tap(find.textContaining('Soldées').first);
      await tester.pumpAndSettle();
      expect(address().toString(), '/home/paie-avances?filtre=settled');

      final reopened = await pumpPayrollScreen(
        tester,
        snapshot: snapshot(),
        location: address().toString(),
        child: screen,
        onRouter: (r) => router = r,
      );
      await tester.pumpAndSettle();
      expect(reopened.cubit.state.advanceFilter, PayrollAdvanceFilter.settled);
    });
  });

  group('les raccourcis', () {
    testWidgets('Ctrl+N ouvre « Nouvelle avance »', (tester) async {
      await wide(tester);
      await pumpPayrollScreen(
        tester,
        snapshot: snapshot(),
        child: const PayrollAdvancesScreen(),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.byType(PayrollAdvanceDialog), findsOneWidget);
    });

    testWidgets('F5 sur la configuration tire les flux, sans recharger', (
      tester,
    ) async {
      await wide(tester);
      final pumped = await pumpPayrollScreen(
        tester,
        snapshot: snapshot(),
        child: const PayrollRefreshShortcut(child: PayrollSettingsScreen()),
      );
      await tester.pumpAndSettle();
      clearInteractions(pumped.signals);

      final handled = await tester.sendKeyEvent(LogicalKeyboardKey.f5);
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      verify(() => pumped.signals.pull()).called(1);
    });
  });

  group('le tableau de bord', () {
    late _MockDashboards dashboards;
    late GoRouter router;

    setUpAll(() => registerFallbackValue(PayrollDashboardFilter.all));

    setUp(() {
      final json = payrollDashboardFixture();
      final usd = (json['currencies'] as List).first as Map<String, dynamic>;
      final cdf = jsonDecode(jsonEncode(usd)) as Map<String, dynamic>
        ..['currency'] = 'CDF';
      json['currencies'] = [usd, cdf];
      final dashboard = PayrollDashboardJson.fromJson(json);
      dashboards = _MockDashboards();
      when(
        () => dashboards.read(
          any(),
          filter: any(named: 'filter'),
          query: any(named: 'query'),
        ),
      ).thenAnswer((_) async => Right(dashboard));
    });

    Future<PayrollDashboardCubit> pump(
      WidgetTester tester,
      String location,
    ) async {
      final signals = _MockSignals();
      when(() => signals.flush()).thenAnswer((_) async {});
      final cubit = PayrollDashboardCubit(
        read: GetPayrollDashboardUseCase(dashboards),
        documents: FetchPayslipUseCase(_MockPayslips()),
        signals: signals,
        now: () => DateTime(2026, 9, 28, 10),
        debounce: Duration.zero,
      );
      addTearDown(cubit.close);
      final auth = _MockAuthBloc();
      const state = AuthState(status: AuthStatus.authenticated);
      when(() => auth.state).thenReturn(state);
      whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
      router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: '/home/:subMenuId',
            builder: (_, _) => const Scaffold(
              body: PayrollDashboardLocation(child: PayrollDashboardScreen()),
            ),
            routes: [
              GoRoute(
                path: ':agentId',
                builder: (_, state) =>
                    Text('fiche ${state.pathParameters['agentId']}'),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiBlocProvider(
          key: UniqueKey(),
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider.value(value: cubit..load()),
          ],
          child: MaterialApp.router(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // L'adresse d'une fiche poussée (`extra` compris) parvient au
            // navigateur.
            routerConfig: ReflectedRecordsParser.configOf(router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return cubit;
    }

    Uri address() => router.routerDelegate.currentConfiguration.uri;

    testWidgets('la devise choisie s\'inscrit ; F5 la restitue ; la '
        'première est l\'adresse nue', (tester) async {
      await wide(tester);
      final cubit = await pump(tester, '/home/paie-tableau-de-bord');
      expect(cubit.state.section?.currency, 'USD');
      expect(address().queryParameters, isEmpty);

      await tester.tap(find.text('CDF').first);
      await tester.pumpAndSettle();
      expect(address().queryParameters['devise'], 'CDF');

      final reopened = await pump(tester, address().toString());
      expect(reopened.state.section?.currency, 'CDF');
      expect(address().queryParameters['devise'], 'CDF');

      await tester.tap(find.text('USD').first);
      await tester.pumpAndSettle();
      expect(address().queryParameters.containsKey('devise'), isFalse);
    });

    testWidgets('la fiche d\'un agent garde la devise du dessous dans son '
        'adresse', (tester) async {
      await wide(tester);
      await pump(tester, '/home/paie-tableau-de-bord?devise=CDF');

      final eye = find.byTooltip("Ouvrir la fiche de l'agent").first;
      await tester.ensureVisible(eye);
      await tester.tap(eye);
      await tester.pumpAndSettle();

      final pushed = router.routeInformationProvider.value.uri;
      expect(pushed.path, startsWith('/home/paie-tableau-de-bord/'));
      expect(pushed.queryParameters['devise'], 'CDF');
      expect(pushed.queryParameters['mois-agent'], isNotNull);
    });
  });
}
