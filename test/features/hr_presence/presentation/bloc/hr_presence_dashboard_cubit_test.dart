import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_presence_dashboard_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

import '../../hr_presence_builders.dart';

class _MockGet extends Mock implements GetHrAttendanceDashboardUseCase {}

class _MockCount extends Mock implements CountUnsyncedStaffAttendanceUseCase {}

class _MockSignals extends Mock implements StaffSyncSignals {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      DashboardWindow(from: DateTime(2026), to: DateTime(2026)),
    );
  });

  // Vendredi 23 octobre 2026, 10 h à Kinshasa.
  final now = DateTime.utc(2026, 10, 23, 9);
  late _MockGet get;
  late _MockCount count;
  late _MockSignals signals;
  void Function()? onSignal;

  HrPresenceDashboardCubit build() {
    final cubit = HrPresenceDashboardCubit(
      getDashboard: get,
      countUnsynced: count,
      signals: signals,
      now: () => now,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() {
    get = _MockGet();
    count = _MockCount();
    signals = _MockSignals();
    onSignal = null;
    when(() => signals.watch(any())).thenAnswer((invocation) {
      onSignal = invocation.positionalArguments.first as void Function();
      return () {};
    });
    when(() => get(any())).thenAnswer((_) async => Right(dashboardOf()));
    when(
      () => count(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => const Right(4));
  });

  DashboardWindow asked() =>
      verify(() => get(captureAny())).captured.last as DashboardWindow;

  test('s\'ouvre sur « Ce mois » : du 1er à aujourd\'hui', () async {
    final cubit = build();
    await cubit.start(yearStart: DateTime(2026, 9, 1));

    expect(cubit.state.period, DashboardPeriod.month);
    expect(
      asked(),
      DashboardWindow(from: DateTime(2026, 10), to: DateTime(2026, 10, 23)),
    );
    expect(cubit.state.status, HrPresenceDashboardStatus.ready);
    expect(cubit.state.unsynced, 4);
    verify(() => count(from: '2026-10-01', to: '2026-10-23')).called(1);
  });

  test('« Cette année » part de la rentrée', () async {
    final cubit = build();
    await cubit.start(yearStart: DateTime(2026, 9, 1));
    await cubit.setPeriod(DashboardPeriod.year);

    expect(asked().from, DateTime(2026, 9, 1));
  });

  test(
    'la période précise s\'ouvre sur J−14 → J, sans passer la rentrée',
    () async {
      final cubit = build();
      await cubit.start(yearStart: DateTime(2026, 9, 1));
      await cubit.setPeriod(DashboardPeriod.custom);
      expect(
        asked(),
        DashboardWindow(
          from: DateTime(2026, 10, 9),
          to: DateTime(2026, 10, 23),
        ),
      );

      final early = build();
      await early.start(yearStart: DateTime(2026, 10, 19));
      await early.setPeriod(DashboardPeriod.custom);
      expect(asked().from, DateTime(2026, 10, 19));
    },
  );

  test('changer de fenêtre montre le squelette ; une réponse dépassée est '
      'jetée', () async {
    final cubit = build();
    await cubit.start();
    final slow = Completer<Either<Failure, HrAttendanceDashboard>>();
    when(() => get(any())).thenAnswer((_) => slow.future);
    unawaited(cubit.setPeriod(DashboardPeriod.week));
    expect(cubit.state.status, HrPresenceDashboardStatus.loading);
    expect(cubit.state.dashboard, isNull);

    when(
      () => get(any()),
    ).thenAnswer((_) async => Right(dashboardOf(classDays: 2)));
    await cubit.setPeriod(DashboardPeriod.today);
    slow.complete(Right(dashboardOf(classDays: 99)));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.period, DashboardPeriod.today);
    expect(cubit.state.dashboard!.classDays, 2);
  });

  test(
    'une relecture garde les chiffres, et son échec ne les efface pas',
    () async {
      final cubit = build();
      await cubit.start();
      final shown = cubit.state.dashboard;
      when(
        () => get(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('hors ligne')));
      await cubit.reload();

      expect(cubit.state.status, HrPresenceDashboardStatus.ready);
      expect(cubit.state.dashboard, shown);
    },
  );

  test(
    'une autre fenêtre ne garde pas le compte local de la précédente',
    () async {
      final cubit = build();
      await cubit.start();
      expect(cubit.state.unsynced, 4);
      when(
        () => count(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => const Left(StorageFailure('—')));
      await cubit.setPeriod(DashboardPeriod.week);

      expect(cubit.state.unsynced, 0);
    },
  );

  test('un premier échec s\'affiche', () async {
    when(
      () => get(any()),
    ).thenAnswer((_) async => const Left(UnauthorizedFailure('403')));
    final cubit = build();
    await cubit.start();

    expect(cubit.state.status, HrPresenceDashboardStatus.failure);
    expect(cubit.state.failure, isA<UnauthorizedFailure>());
  });

  test('un envoi achevé fait relire', () async {
    final cubit = build();
    await cubit.start();
    clearInteractions(get);
    onSignal!();
    await Future<void>.delayed(Duration.zero);

    verify(() => get(any())).called(1);
  });

  test('l\'adresse : une période, des bornes précises', () async {
    final cubit = build();
    await cubit.start();
    final range = DashboardWindow(
      from: DateTime(2026, 10, 5),
      to: DateTime(2026, 10, 9),
    );
    await cubit.applyLocation(period: DashboardPeriod.custom, range: range);

    expect(cubit.state.period, DashboardPeriod.custom);
    expect(asked(), range);
  });

  test('la recherche filtre sans retrier, accents et casse ignorés', () async {
    final cubit = build();
    await cubit.start();
    cubit.setText('secretaire');
    expect(cubit.state.visibleStaff.map((r) => r.agent.staffMemberId), ['a-1']);
    cubit.setText('');
    expect(cubit.state.visibleStaff.map((r) => r.agent.staffMemberId), [
      'a-1',
      'a-2',
      'a-3',
    ]);
  });
}
