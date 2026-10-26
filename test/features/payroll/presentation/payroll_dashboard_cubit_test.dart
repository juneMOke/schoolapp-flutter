import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/data/dashboard/payroll_dashboard_json.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_dashboard_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_dashboard_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

import '../data/payroll_dashboard_json_test.dart' show payrollDashboardFixture;

class _MockRepository extends Mock implements PayrollDashboardRepository {}

class _MockPayslips extends Mock implements PayslipRepository {}

class _MockSignals extends Mock implements StaffSyncSignals {}

void main() {
  late _MockRepository repository;
  late _MockPayslips payslips;
  late _MockSignals signals;
  final dashboard = PayrollDashboardJson.fromJson(payrollDashboardFixture());

  setUpAll(() => registerFallbackValue(PayrollDashboardFilter.all));

  setUp(() {
    repository = _MockRepository();
    payslips = _MockPayslips();
    signals = _MockSignals();
    when(() => signals.flush()).thenAnswer((_) async {});
    when(
      () => repository.read(
        any(),
        filter: any(named: 'filter'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => Right(dashboard));
  });

  PayrollDashboardCubit cubit() => PayrollDashboardCubit(
    read: GetPayrollDashboardUseCase(repository),
    documents: FetchPayslipUseCase(payslips),
    signals: signals,
    now: () => DateTime(2026, 10, 26, 10),
    debounce: Duration.zero,
  );

  test('la file part avant la requête, sur le mois en cours', () async {
    final c = cubit();
    addTearDown(c.close);

    await c.load();

    verifyInOrder([
      () => signals.flush(),
      () => repository.read('2026-10', filter: PayrollDashboardFilter.all),
    ]);
    expect(c.state.load, PayrollDashboardLoad.ready);
    expect(c.state.dashboard, dashboard);
  });

  test('un mois à venir est ramené au mois en cours', () async {
    final c = cubit();
    addTearDown(c.close);
    await c.load();

    await c.showMonth('2027-01');
    expect(c.state.month, '2026-10');
    await c.showMonth('2026-09');
    expect(c.state.month, '2026-09');
    verify(
      () => repository.read('2026-09', filter: PayrollDashboardFilter.all),
    ).called(1);
  });

  test('changer de mois repasse par le squelette', () async {
    final c = cubit();
    addTearDown(c.close);
    await c.load();
    final states = <PayrollDashboardState>[];
    final sub = c.stream.listen(states.add);

    await c.showMonth('2026-08');
    await sub.cancel();

    expect(states.any((s) => s.load == PayrollDashboardLoad.loading), isTrue);
  });

  test('un filtre garde l écran, et un échec ne l efface pas', () async {
    final c = cubit();
    addTearDown(c.close);
    await c.load();
    when(
      () => repository.read(
        any(),
        filter: PayrollDashboardFilter.settled,
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    await c.setFilter(PayrollDashboardFilter.settled);

    expect(c.state.load, PayrollDashboardLoad.ready);
    expect(c.state.dashboard, dashboard);
    expect(c.state.refreshing, isFalse);
  });

  test('sans écran, un échec s affiche', () async {
    when(
      () => repository.read(
        any(),
        filter: any(named: 'filter'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    final c = cubit();
    addTearDown(c.close);

    await c.load();

    expect(c.state.load, PayrollDashboardLoad.failure);
    expect(c.state.failure, isA<NetworkFailure>());
  });

  test('une réponse dépassée est jetée', () async {
    final slow = Completer<Either<Failure, PayrollDashboard>>();
    when(
      () => repository.read('2026-10', filter: any(named: 'filter')),
    ).thenAnswer((_) => slow.future);
    final c = cubit();
    addTearDown(c.close);

    final first = c.load();
    await c.showMonth('2026-09');
    slow.complete(
      const Right(
        PayrollDashboard(
          month: '2026-10',
          status: PayrollMonthStatus.none,
          situationAt: 'x',
        ),
      ),
    );
    await first;

    expect(c.state.month, '2026-09');
    expect(c.state.dashboard, dashboard);
  });

  test('le PDF part sur la requête qui a rempli l écran', () async {
    when(
      () => payslips.dashboard(
        any(),
        filter: any(named: 'filter'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    final c = cubit();
    addTearDown(c.close);
    await c.showMonth('2026-09');
    await c.setFilter(PayrollDashboardFilter.outstanding);
    c.setSearch('Mayala');
    await Future<void>.delayed(Duration.zero);
    await pumpEventQueue();

    await c.pdf();

    verify(
      () =>
          payslips.dashboard('2026-09', filter: 'OUTSTANDING', query: 'Mayala'),
    ).called(1);
  });

  test('l adresse : un seul rechargement pour le mois et le filtre', () async {
    final c = cubit();
    addTearDown(c.close);
    await c.load();
    clearInteractions(repository);

    await c.applyLocation(
      month: '2026-09',
      filter: PayrollDashboardFilter.settled,
    );

    verify(
      () => repository.read('2026-09', filter: PayrollDashboardFilter.settled),
    ).called(1);
    expect(c.state.filter, PayrollDashboardFilter.settled);
  });
}
