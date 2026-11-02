import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/find_expense_use_case.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_deduction_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_advance_request_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_arrears_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_circuit_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_deduction_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_money_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_settings_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_commands.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_deduction_commands.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_page.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/router/reflected_records_parser.dart';

class MockPayrollRepository extends Mock implements PayrollRepository {}

class _MockPayslips extends Mock implements PayslipRepository {}

class _MockSignals extends Mock implements StaffSyncSignals {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// L'écran de la paie ([child], par défaut celui de la Paie) sur [snapshot],
/// la taille de la fenêtre laissée à l'appelant (tests de formats). Rend le
/// cubit, pour changer de mois, et le dépôt, pour vérifier une écriture.
Future<
  ({
    PayrollCubit cubit,
    MockPayrollRepository repository,
    StaffSyncSignals signals,
  })
>
pumpPayrollScreen(
  WidgetTester tester, {
  required PayrollSnapshot snapshot,
  List<Perm> permissions = const [Perm.hrPayRead, Perm.hrPayWrite],
  Widget child = const PayrollScreen(),

  /// Les dépenses, pour trancher une demande d'avance depuis la Paie.
  ExpenseRepository? expenses,

  /// Les PDF du serveur (bulletins, état de paie, tableau de bord).
  PayslipRepository? payslips,

  /// Les rubriques de l'école et leurs saisies.
  PayrollDeductionRepository? deductions,

  /// Un geste posé avant que la tablette ne soit lue (un mois d'adresse).
  void Function(PayrollCubit cubit)? beforeLoad,

  /// Une adresse d'ouverture (un F5), sous un vrai routeur : `/home/:subMenuId`
  /// bâtit [child] ; `/home/:subMenuId/:agentId` bâtit [routeChild] depuis
  /// l'état de sa route (l'écran du dessous reste alors vide). [onRouter]
  /// reçoit ce routeur.
  String? location,
  Widget Function(GoRouterState state)? routeChild,
  void Function(GoRouter router)? onRouter,
}) async {
  final repository = MockPayrollRepository();
  when(() => repository.load()).thenAnswer((_) async => Right(snapshot));
  when(
    () => repository.disburseAll(any()),
  ).thenAnswer((_) async => const Right(unit));
  final signals = _MockSignals();
  when(() => signals.watch(any())).thenReturn(() {});
  when(() => signals.pull()).thenAnswer((_) async {});
  when(() => signals.flush()).thenAnswer((_) async {});
  final cubit = PayrollCubit(
    load: LoadPayrollUseCase(repository),
    signals: signals,
    commands: PayrollCommands(
      variables: SavePayrollVariablesUseCase(repository),
      payoutPolicy: SavePayrollPayoutPolicyUseCase(repository),
      payArrears: PayPayrollArrearsUseCase(repository),
      priority: SetPayrollArrearsPriorityUseCase(repository),
      decide: expenses == null
          ? null
          : DecideSalaryAdvanceUseCase(
              FindExpenseUseCase(expenses),
              ApplyExpenseGestureUseCase(expenses),
            ),
      gesture: RecordPayrollGestureUseCase(repository),
      disburse: DisbursePayrollUseCase(repository),
      cancelDisbursement: CancelPayrollDisbursementUseCase(repository),
      grant: GrantSalaryAdvanceUseCase(repository),
      cancelAdvance: CancelSalaryAdvanceUseCase(repository),
      profile: SaveStaffPayProfileUseCase(repository),
      settings: SavePayrollSettingsUseCase(repository),
      share: RecordPayslipShareUseCase(repository),
      payslip: FetchPayslipUseCase(payslips ?? _MockPayslips()),
      deductions: deductions == null
          ? null
          : PayrollDeductionCommands(
              create: CreatePayrollDeductionTypeUseCase(deductions),
              update: UpdatePayrollDeductionTypeUseCase(deductions),
              move: MovePayrollDeductionTypeUseCase(deductions),
              remove: RemovePayrollDeductionTypeUseCase(deductions),
              entries: SavePayrollDeductionsUseCase(deductions),
              dismiss: DismissPayrollDeductionUseCase(deductions),
            ),
    ),
    now: () => DateTime(2026, 10, 26, 10),
  );
  final auth = _MockAuthBloc();
  final state = AuthState(
    status: AuthStatus.authenticated,
    permissions: [for (final p in permissions) p.wire],
  );
  when(() => auth.state).thenReturn(state);
  whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
  addTearDown(cubit.close);
  beforeLoad?.call(cubit);
  if (location == null) {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<AuthBloc>.value(
            value: auth,
            child: BlocProvider.value(value: cubit..load(), child: child),
          ),
        ),
      ),
    );
  } else {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: AppRoutesNames.homeSubMenuRoute,
          builder: (_, _) =>
              Scaffold(body: routeChild == null ? child : const SizedBox()),
          routes: [
            GoRoute(
              path: ':agentId',
              builder: (_, state) =>
                  Scaffold(body: routeChild?.call(state) ?? child),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    onRouter?.call(router);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        key: UniqueKey(),
        value: auth,
        child: BlocProvider.value(
          value: cubit..load(),
          child: MaterialApp.router(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: ReflectedRecordsParser.configOf(router),
          ),
        ),
      ),
    );
  }
  await tester.pump();
  await tester.pump();
  return (cubit: cubit, repository: repository, signals: signals);
}
