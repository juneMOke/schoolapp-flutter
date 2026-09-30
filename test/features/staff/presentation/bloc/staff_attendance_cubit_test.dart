import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

import '../../staff_builders.dart';

class _MockLoad extends Mock implements LoadStaffAttendanceUseCase {}

class _MockSignals extends Mock implements StaffSyncSignals {}

class _MockCommands extends Mock implements StaffAttendanceCommands {}

void main() {
  late _MockLoad load;
  late _MockSignals signals;
  final snapshot = StaffAttendanceSnapshot(
    members: [member('m-1')],
    records: const {},
    locks: const {},
    settings: StaffAttendanceSettings.defaults,
    hasEverSynced: true,
  );

  setUp(() {
    load = _MockLoad();
    signals = _MockSignals();
    when(() => signals.watch(any())).thenReturn(() {});
    when(() => signals.pull()).thenAnswer((_) async {});
    when(
      () => load(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => Right(snapshot));
  });

  StaffAttendanceCubit cubitAt(DateTime now) => StaffAttendanceCubit(
    load: load,
    signals: signals,
    commands: _MockCommands(),
    now: () => now,
  );

  test('lit le mois du registre, puis tire les flux', () async {
    final cubit = cubitAt(DateTime(2026, 9, 29, 9));
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.load, StaffAttendanceLoad.ready);
    verify(() => load(from: '2026-09-01', to: '2026-09-30')).called(1);
    verify(() => signals.pull()).called(1);
  });

  test('le week-end, le registre s\'ouvre sur le vendredi', () {
    final cubit = cubitAt(DateTime(2026, 10, 4, 9)); // dimanche
    addTearDown(cubit.close);

    expect(cubit.state.day, '2026-10-02');
    expect(cubit.state.today, '2026-10-04');
  });

  test('jamais au-delà d\'aujourd\'hui, ni du mois en cours', () async {
    final cubit = cubitAt(DateTime(2026, 9, 29, 9));
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.stepDay(1);
    await cubit.stepMonth(1);

    expect(cubit.state.day, '2026-09-29');
    expect(cubit.state.month, '2026-09');
  });

  test('« Aujourd\'hui » ramène au vendredi le week-end', () async {
    final cubit = cubitAt(DateTime(2026, 10, 4, 9)); // dimanche
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.stepDay(-1);
    expect(cubit.state.day, '2026-10-01');
    await cubit.goToday();

    expect(cubit.state.day, '2026-10-02');
    expect(cubit.state.isToday, isTrue);
  });

  test('changer de mois relit une plage de deux mois', () async {
    final cubit = cubitAt(DateTime(2026, 10, 1, 9));
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.stepMonth(-1);

    expect(cubit.state.month, '2026-09');
    verify(() => load(from: '2026-09-01', to: '2026-10-31')).called(1);
  });

  test('deux annonces identiques restent deux annonces', () async {
    final cubit = cubitAt(DateTime(2026, 9, 29, 9));
    addTearDown(cubit.close);
    await cubit.load();
    const notice = StaffAttendanceNotice(StaffAttendanceNoticeKind.dayFrozen);

    cubit.announce(notice);
    final first = cubit.state.notice;
    cubit.announce(notice);

    expect(cubit.state.notice, isNot(first));
    expect(cubit.state.notice?.kind, StaffAttendanceNoticeKind.dayFrozen);
  });

  test('clore : pas avant le dernier jour du mois (contrat v3, C2)', () async {
    StaffAttendanceState at(DateTime now) => cubitAt(now).state.copyWith(
      snapshot: StaffAttendanceSnapshot(
        members: const [],
        records: const {},
        locks: const {},
        settings: StaffAttendanceSettings.defaults,
        schoolYear: const StaffSchoolYear(start: '2026-09-01'),
        hasEverSynced: true,
      ),
    );

    expect(at(DateTime(2026, 9, 29, 9)).canCloseMonth, isFalse);
    expect(at(DateTime(2026, 9, 30, 9)).canCloseMonth, isTrue);
  });

  test('ouvrir un agent bascule sur sa fiche mensuelle', () {
    final cubit = cubitAt(DateTime(2026, 9, 29, 9));
    addTearDown(cubit.close);

    cubit.openAgent('m-1');

    expect(cubit.state.tab, StaffAttendanceTab.agentMonth);
    expect(cubit.state.agentId, 'm-1');
  });
}
