import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';

import '../../hr_presence_builders.dart';

class _MockMonth extends Mock implements GetHrAttendanceAgentMonthUseCase {}

class _MockYear extends Mock implements GetHrAttendanceAgentYearUseCase {}

class _MockSource extends Mock implements StaffSnapshotSource {}

/// Un jour corrigé depuis la feuille : le calendrier montre la ligne de la
/// tablette jusqu'à ce que le serveur, relu à chaque synchro, dise pareil.
void main() {
  late _MockMonth month;
  late void Function() onSignal;

  const day = '2026-10-01';
  const absent = StaffAttendanceRecord(
    id: 'r-1',
    staffMemberId: 'a-1',
    workDate: day,
    status: PresenceStatus.absent,
    syncState: RecordSyncState.pending,
  );

  HrPresenceFicheCubit build() {
    month = _MockMonth();
    when(
      () => month(any(), month: any(named: 'month')),
    ).thenAnswer((_) async => Right(agentMonthOf()));
    final source = _MockSource();
    when(
      () => source.read(),
    ).thenAnswer((_) async => const Left(StorageFailure('—')));
    when(() => source.watch(any())).thenAnswer((invocation) {
      onSignal = invocation.positionalArguments.first as void Function();
      return () {};
    });
    final cubit = HrPresenceFicheCubit(
      getMonth: month,
      getYear: _MockYear(),
      source: source,
      args: (
        agentId: 'a-1',
        yearly: false,
        month: '2026-10',
        yearStart: DateTime(2026, 9, 1),
      ),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('le jour noté reste tant que le serveur dit autre chose', () async {
    final cubit = build();
    await cubit.load();
    cubit.noteLocalDay(day, absent);
    expect(cubit.state.localDays, {day: absent});

    onSignal();
    await settle();
    // Le serveur montre encore « présent à 07:25 ».
    expect(cubit.state.localDays, {day: absent});
    // Relu sans squelette.
    expect(cubit.state.status, HrPresenceFicheStatus.ready);
  });

  test(
    'le serveur rattrape la tablette : le jour quitte la tablette',
    () async {
      final cubit = build();
      await cubit.load();
      final present = StaffAttendanceRecord(
        id: 'r-1',
        staffMemberId: 'a-1',
        workDate: day,
        status: PresenceStatus.present,
        arrival: ClockTime.tryParse('07:25'),
      );
      cubit.noteLocalDay(day, present);

      onSignal();
      await settle();
      expect(cubit.state.localDays, isEmpty);
    },
  );

  test('changer d\'agent oublie les jours notés', () async {
    final cubit = build();
    await cubit.load();
    cubit.noteLocalDay(day, absent);
    await cubit.openAgent('a-2');
    expect(cubit.state.localDays, isEmpty);
    // Le jour du serveur reste typé pour le calendrier.
    expect(agentMonthOf().days.first, isA<HrAttendanceDay>());
  });
}
