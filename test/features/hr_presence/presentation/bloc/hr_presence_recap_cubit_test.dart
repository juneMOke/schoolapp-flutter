import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

import '../../hr_presence_builders.dart';

class _MockRecap extends Mock implements GetHrAttendanceRecapUseCase {}

class _MockLoad extends Mock implements LoadStaffAttendanceUseCase {}

class _MockCount extends Mock implements CountUnsyncedStaffAttendanceUseCase {}

class _MockCommands extends Mock implements StaffAttendanceCommands {}

class _MockSignals extends Mock implements StaffSyncSignals {}

StaffAttendanceSnapshot snapshotWith({
  StaffAttendanceLock? lock,
  Map<String, Map<String, StaffAttendanceRecord>> records = const {},
}) => StaffAttendanceSnapshot(
  members: const [],
  records: records,
  locks: lock == null
      ? const {}
      : {StaffAttendanceSnapshot.lockKey(lock.kind, lock.periodStart): lock},
  settings: StaffAttendanceSettings.defaults,
  hasEverSynced: true,
);

void main() {
  late _MockRecap recap;
  late _MockLoad load;
  late _MockCount count;
  late _MockCommands commands;
  void Function()? onSignal;

  setUp(() {
    recap = _MockRecap();
    load = _MockLoad();
    count = _MockCount();
    commands = _MockCommands();
    when(() => recap(any())).thenAnswer((_) async => Right(recapOf()));
    when(
      () => load(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => Right(snapshotWith()));
    when(
      () => count.byAgent(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => const Right({'a-1': 2}));
  });

  HrPresenceRecapCubit build() {
    final signals = _MockSignals();
    when(() => signals.watch(any())).thenAnswer((invocation) {
      onSignal = invocation.positionalArguments.first as void Function();
      return () {};
    });
    final cubit = HrPresenceRecapCubit(
      getRecap: recap,
      loadLocal: load,
      countUnsynced: count,
      commands: commands,
      signals: signals,
      yearStart: DateTime(2026, 9, 1),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('le mois en cours : le serveur, puis la tablette', () async {
    final cubit = build();
    await cubit.load();
    await settle();

    verify(() => recap('2026-10')).called(1);
    verify(() => count.byAgent(from: '2026-10-01', to: '2026-10-31')).called(1);
    expect(cubit.state.status, HrPresenceRecapStatus.ready);
    expect(cubit.state.unsynced, 2);
    expect(cubit.state.isClosed, isFalse);
  });

  test(
    'une clôture posée ici et pas encore reçue compte comme close',
    () async {
      when(
        () => load(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => Right(
          snapshotWith(
            lock: const StaffAttendanceLock(
              kind: StaffAttendanceLockKind.month,
              periodStart: '2026-10-01',
              locked: true,
              syncState: RecordSyncState.pending,
            ),
          ),
        ),
      );
      final cubit = build();
      await cubit.load();
      await settle();

      expect(cubit.state.recap!.closed, isFalse);
      expect(cubit.state.isClosed, isTrue);
    },
  );

  test('clôturer passe par le geste du Pointage, une seule fois', () async {
    when(() => commands.closeMonth(any())).thenAnswer(
      (_) async => const StaffAttendanceNotice(
        StaffAttendanceNoticeKind.monthClosed,
        month: '2026-09',
      ),
    );
    final cubit = build();
    await cubit.applyLocation('2026-09');
    await settle();
    final notice = await cubit.closeMonth();

    verify(() => commands.closeMonth('2026-09')).called(1);
    expect(notice?.kind, StaffAttendanceNoticeKind.monthClosed);
    expect(cubit.state.closing, isFalse);
  });

  test('un envoi achevé relit sans squelette', () async {
    final cubit = build();
    await cubit.load();
    await settle();
    final states = <HrPresenceRecapStatus>[];
    final sub = cubit.stream.listen((s) => states.add(s.status));
    onSignal!();
    await settle();
    await sub.cancel();

    expect(states, isNot(contains(HrPresenceRecapStatus.loading)));
    verify(() => recap('2026-10')).called(2);
  });

  test('puces de contrat et recherche', () async {
    final cubit = build();
    await cubit.load();
    await settle();
    expect(cubit.state.contractCounts, {
      StaffContractFilter.permanent: 1,
      StaffContractFilter.vacataire: 1,
      StaffContractFilter.conventionne: 1,
    });
    cubit.toggleContract(StaffContractFilter.vacataire);
    expect(cubit.state.visibleRows.single.agent.staffMemberId, 'a-2');
    cubit.toggleContract(StaffContractFilter.vacataire);
    expect(cubit.state.visibleRows, hasLength(3));
    cubit.setText('mayala');
    expect(cubit.state.visibleRows.single.agent.staffMemberId, 'a-3');
  });

  test('l\'adresse : un mois permis, sinon le mois en cours', () async {
    final cubit = build();
    await cubit.load();
    await cubit.applyLocation('2026-08');
    expect(cubit.state.month, '2026-10');
    await cubit.applyLocation('2026-09');
    expect(cubit.state.month, '2026-09');
  });

  test('le sélecteur : un mois permis, sinon rien', () async {
    final cubit = build();
    await cubit.load();
    await cubit.showMonth('2026-09');
    expect(cubit.state.month, '2026-09');
    await cubit.showMonth('2026-11');
    expect(cubit.state.month, '2026-09');
    await cubit.showMonth('2026-08');
    expect(cubit.state.month, '2026-09');
  });

  test('l\'adresse porte aussi le contrat', () async {
    final cubit = build();
    await cubit.load();
    cubit.applyContract(StaffContractFilter.vacataire);
    expect(cubit.state.contract, StaffContractFilter.vacataire);
    cubit.applyContract(null);
    expect(cubit.state.contract, isNull);
  });

  test('les pointages en attente, agent par agent, font le total', () async {
    when(
      () => count.byAgent(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => const Right({'a-1': 2, 'a-3': 1}));
    final cubit = build();
    await cubit.load();
    await settle();

    expect(cubit.state.unsyncedByAgent, {'a-1': 2, 'a-3': 1});
    expect(cubit.state.unsynced, 3);
    expect(cubit.state.unsyncedOf('a-2'), 0);
  });

  test('« avec retenue » venu de l\'adresse ne filtre pas une école qui ne '
      'retient pas', () async {
    when(
      () => recap(any()),
    ).thenAnswer((_) async => Right(recapOf(absenceDeductionEnabled: false)));
    final cubit = build();
    await cubit.load();
    await settle();
    cubit.applyDeducted(true);

    expect(cubit.state.deductedFilter, isFalse);
    expect(cubit.state.hasFilters, isFalse);
    expect(cubit.state.visibleRows.length, cubit.state.recap!.staff.length);
  });
}
