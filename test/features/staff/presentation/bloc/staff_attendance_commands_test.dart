import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';

import '../../staff_builders.dart';

class _MockSave extends Mock implements SaveStaffAttendanceUseCase {}

class _MockGesture extends Mock
    implements RecordStaffAttendanceGestureUseCase {}

class _MockSettings extends Mock
    implements SaveStaffAttendanceSettingsUseCase {}

const _day = '2026-09-29';

StaffAttendanceSnapshot _snapshot({
  Map<String, Map<String, StaffAttendanceRecord>> records = const {},
  bool validated = false,
}) => StaffAttendanceSnapshot(
  members: [
    member('m-1', contracts: [period(StaffContractKind.permanent)]),
    member(
      'm-2',
      firstName: 'Élodie',
      contracts: [period(StaffContractKind.permanent)],
    ),
  ],
  records: records,
  locks: {
    if (validated)
      StaffAttendanceSnapshot.lockKey(
        StaffAttendanceLockKind.day,
        _day,
      ): const StaffAttendanceLock(
        kind: StaffAttendanceLockKind.day,
        periodStart: _day,
        locked: true,
      ),
  },
  settings: StaffAttendanceSettings.defaults,
  hasEverSynced: true,
);

void main() {
  late _MockSave save;
  late _MockGesture gesture;
  late StaffAttendanceCommands commands;

  setUpAll(() => registerFallbackValue(StaffAttendanceGesture.validateDay));

  setUp(() {
    save = _MockSave();
    gesture = _MockGesture();
    commands = StaffAttendanceCommands(
      save: save,
      gesture: gesture,
      settings: _MockSettings(),
      // 08:05, au-delà de 07:30 + 10 min.
      now: () => DateTime(2026, 9, 29, 8, 5),
    );
    when(() => save(any())).thenAnswer((_) async => const Right(unit));
    when(
      () => gesture(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  StaffDayRegister registerOf(StaffAttendanceSnapshot snapshot) =>
      StaffDayRegister.build(snapshot, day: _day, query: StaffDayQuery.none);

  List<StaffAttendanceRecord> saved() =>
      verify(() => save(captureAny())).captured.single
          as List<StaffAttendanceRecord>;

  test(
    'un toucher sur « à pointer » pose présent à l\'heure de début',
    () async {
      final snapshot = _snapshot();

      await commands.cycle(snapshot, registerOf(snapshot).all.first);

      final record = saved().single;
      expect(record.status, StaffAttendanceStatus.present);
      expect(record.arrival, StaffClockTime.tryParse('07:30'));
      expect(record.staffMemberId, 'm-1');
      expect(record.workDate, _day);
    },
  );

  test('retoucher le statut actif l\'efface, et le dit', () async {
    final present = StaffAttendanceRecord(
      id: 'r-1',
      staffMemberId: 'm-1',
      workDate: _day,
      status: StaffAttendanceStatus.present,
      arrival: StaffClockTime.tryParse('07:30'),
    );
    final snapshot = _snapshot(
      records: {
        'm-1': {_day: present},
      },
    );

    final notice = await commands.choose(
      snapshot,
      registerOf(snapshot).all.first,
      StaffAttendanceStatus.present,
    );

    expect(saved().single.status, StaffAttendanceStatus.none);
    expect(notice?.kind, StaffAttendanceNoticeKind.cleared);
  });

  test('un jour validé refuse le geste sans rien écrire', () async {
    final snapshot = _snapshot(validated: true);

    final notice = await commands.cycle(
      snapshot,
      registerOf(snapshot).all.first,
    );

    expect(notice?.kind, StaffAttendanceNoticeKind.dayFrozen);
    verifyNever(() => save(any()));
  });

  test('valider en marquant les restants : les pointages partent AVANT le '
      'geste', () async {
    final snapshot = _snapshot();

    final notice = await commands.validateDay(
      snapshot,
      registerOf(snapshot),
      markRemaining: true,
    );

    verifyInOrder([
      () => save(any(that: hasLength(2))),
      () => gesture(StaffAttendanceGesture.validateDay, _day),
    ]);
    expect(notice?.kind, StaffAttendanceNoticeKind.reportValidated);
  });

  test('un refus local DAY_LOCKED se lit « jour figé »', () async {
    when(() => save(any())).thenAnswer(
      (_) async => const Left(ValidationFailure(kStaffDayLockedCode)),
    );
    final snapshot = _snapshot();

    final notice = await commands.markRemainingPresent(
      snapshot,
      registerOf(snapshot),
    );

    expect(notice?.kind, StaffAttendanceNoticeKind.dayFrozen);
  });

  test('restants présents annonce combien', () async {
    final snapshot = _snapshot();

    final notice = await commands.markRemainingPresent(
      snapshot,
      registerOf(snapshot),
    );

    expect(notice?.kind, StaffAttendanceNoticeKind.remainingMarked);
    expect(notice?.count, 2);
  });

  test('clore un mois pose le geste sur son 1er jour', () async {
    await commands.closeMonth('2026-09');

    verify(
      () => gesture(StaffAttendanceGesture.closeMonth, '2026-09-01'),
    ).called(1);
  });
}
