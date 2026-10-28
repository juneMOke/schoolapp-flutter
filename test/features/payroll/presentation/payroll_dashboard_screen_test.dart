import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/payroll/data/dashboard/payroll_dashboard_json.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_dashboard_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_dashboard_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_dashboard_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_header.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import '../data/payroll_dashboard_json_test.dart' show payrollDashboardFixture;

class _MockRepository extends Mock implements PayrollDashboardRepository {}

class _MockPayslips extends Mock implements PayslipRepository {}

class _MockSignals extends Mock implements StaffSyncSignals {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// RH · Paie ▸ Tableau de bord, en ligne : l'écran entier sur la réponse du
/// serveur, et le PDF sur les mêmes paramètres.
void main() {
  final dashboard = PayrollDashboardJson.fromJson(payrollDashboardFixture());
  late _MockRepository repository;
  late _MockPayslips payslips;

  setUpAll(() => registerFallbackValue(PayrollDashboardFilter.all));

  setUp(() {
    repository = _MockRepository();
    payslips = _MockPayslips();
    when(
      () => repository.read(
        any(),
        filter: any(named: 'filter'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => Right(dashboard));
  });

  Future<PayrollDashboardCubit> pump(WidgetTester tester) async {
    final signals = _MockSignals();
    when(() => signals.flush()).thenAnswer((_) async {});
    final cubit = PayrollDashboardCubit(
      read: GetPayrollDashboardUseCase(repository),
      documents: FetchPayslipUseCase(payslips),
      signals: signals,
      now: () => DateTime(2026, 9, 28, 10),
      debounce: Duration.zero,
    );
    addTearDown(cubit.close);
    final auth = _MockAuthBloc();
    const state = AuthState(status: AuthStatus.authenticated);
    when(() => auth.state).thenReturn(state);
    whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: auth),
              BlocProvider.value(value: cubit..load()),
            ],
            child: const PayrollDashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testAtReferenceFormats('Tableau de bord de la paie', (tester, format) async {
    await pump(tester);

    expect(find.text('COÛT PRÉVU'), findsOneWidget);
    expect(find.text('RESTE DÛ'), findsOneWidget);
    expect(find.text('Mois par mois'), findsOneWidget);
    expect(find.text('Arriérés par salarié'), findsOneWidget);
    // Le mois se lit une seule fois, dans le bandeau, à toutes les largeurs.
    expect(find.text('septembre 2026'), findsOneWidget);
    expect(find.text('TABLEAU DE BORD'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ce que chaque salarié perçoit'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('MAYALA Ruth'), findsWidgets);
  });

  testWidgets('le mois du bandeau ouvre le sélecteur, qui ouvre un mois', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = await pump(tester);
    expect(
      tester.getSize(find.byTooltip('Choisir un mois')).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byTooltip('Choisir un mois'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('août 2026'));
    await tester.pumpAndSettle();

    expect(cubit.state.month, '2026-08');
    verify(
      () => repository.read(
        '2026-08',
        filter: any(named: 'filter'),
        query: any(named: 'query'),
      ),
    ).called(1);
  });

  group('PayrollDashboardHeader.firstPickable', () {
    PayrollDashboardState state(String month) =>
        PayrollDashboardState(month: month, currentMonth: '2026-09');

    test('les douze mois qui finissent au mois en cours', () {
      expect(PayrollDashboardHeader.firstPickable(state('2026-05')), '2025-10');
    });

    test('un mois plus ancien, atteint aux flèches, reste choisissable', () {
      expect(PayrollDashboardHeader.firstPickable(state('2024-03')), '2024-03');
    });
  });

  testWidgets('hors ligne au premier chargement : l erreur réseau', (
    tester,
  ) async {
    when(
      () => repository.read(
        any(),
        filter: any(named: 'filter'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    await pump(tester);

    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('COÛT PRÉVU'), findsNothing);
  });

  testWidgets('aucune paie ce mois : le vide propose de la préparer', (
    tester,
  ) async {
    when(
      () => repository.read(
        any(),
        filter: any(named: 'filter'),
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        PayrollDashboard(
          month: '2026-09',
          status: PayrollMonthStatus.none,
          situationAt: '2026-09-28T09:00:00Z',
        ),
      ),
    );

    await pump(tester);

    expect(find.text('Aucune paie pour ce mois'), findsOneWidget);
    expect(find.text('Préparer la paie'), findsOneWidget);
  });

  testWidgets(
    'le PDF part avec le mois, le filtre et la recherche de l écran',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(
        () => payslips.dashboard(
          any(),
          filter: any(named: 'filter'),
          query: any(named: 'query'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      await pump(tester);

      await tester.tap(find.text('Reste à payer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Mayala');
      await tester.pumpAndSettle();
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      verify(
        () => repository.read(
          '2026-09',
          filter: PayrollDashboardFilter.outstanding,
          query: 'Mayala',
        ),
      ).called(1);
      verify(
        () => payslips.dashboard(
          '2026-09',
          filter: 'OUTSTANDING',
          query: 'Mayala',
        ),
      ).called(1);
    },
  );

  testWidgets('un mois d avant la v2 : ni versé ni reste inventés', (
    tester,
  ) async {
    final json = payrollDashboardFixture()
      ..['tracked'] = false
      ..['arrears'] = <Object>[];
    ((json['currencies'] as List).first as Map<String, dynamic>)
      ..remove('progress')
      ..remove('rows')
      ..remove('totals');
    when(
      () => repository.read(
        any(),
        filter: any(named: 'filter'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => Right(PayrollDashboardJson.fromJson(json)));

    await pump(tester);

    expect(find.text('Non suivi avant la v2'), findsNWidgets(2));
    expect(find.text('Ce que chaque salarié perçoit'), findsNothing);
  });
}
