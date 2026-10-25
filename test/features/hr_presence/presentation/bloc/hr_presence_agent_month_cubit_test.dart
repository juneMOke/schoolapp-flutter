import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/agent/hr_presence_agent_month_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';

import '../../../staff/staff_builders.dart';
import '../../hr_presence_builders.dart';

class _MockGet extends Mock implements GetHrAttendanceAgentMonthUseCase {}

class _MockSource extends Mock implements StaffSnapshotSource {}

void main() {
  late _MockGet get;
  late _MockSource source;

  setUp(() {
    get = _MockGet();
    source = _MockSource();
    when(
      () => source.read(),
    ).thenAnswer((_) async => const Left(StorageFailure('pas de fichier')));
    when(
      () => get(any(), month: any(named: 'month')),
    ).thenAnswer((_) async => Right(agentMonthOf()));
  });

  HrPresenceAgentMonthCubit build({String? month, DateTime? yearStart}) {
    final cubit = HrPresenceAgentMonthCubit(
      getMonth: get,
      source: source,
      agentId: 'a-1',
      month: month,
      yearStart: yearStart ?? DateTime(2026, 9, 1),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('le mois demandé, borné entre la rentrée et le mois en cours', () {
    expect(build(month: '2026-09').state.month, '2026-09');
    expect(build(month: '2026-12').state.month, '2026-10');
    expect(build(month: '2026-08').state.month, '2026-09');
    expect(build(month: 'n/a').state.month, '2026-10');
    expect(build().state.month, '2026-10');
  });

  test('on ne recule pas avant la rentrée, on n\'avance pas au-delà du '
      'mois en cours', () async {
    final cubit = build(month: '2026-09');
    await cubit.load();
    expect(cubit.state.canStepBack, isFalse);
    await cubit.stepMonth(-1);
    expect(cubit.state.month, '2026-09');
    await cubit.stepMonth(1);
    expect(cubit.state.month, '2026-10');
    await cubit.stepMonth(1);
    expect(cubit.state.month, '2026-10');
    verify(() => get('a-1', month: '2026-10')).called(1);
  });

  test('changer d\'agent relit ; une réponse dépassée est jetée', () async {
    final cubit = build();
    await cubit.load();
    final slow = Completer<Either<Failure, HrAttendanceAgentMonth>>();
    when(
      () => get('a-2', month: any(named: 'month')),
    ).thenAnswer((_) => slow.future);
    when(
      () => get('a-3', month: any(named: 'month')),
    ).thenAnswer((_) async => Right(agentMonthOf(id: 'a-3')));
    unawaited(cubit.openAgent('a-2'));
    await cubit.openAgent('a-3');
    slow.complete(Right(agentMonthOf(id: 'a-2')));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.agentId, 'a-3');
    expect(cubit.state.data!.agent.staffMemberId, 'a-3');
  });

  test('un échec s\'affiche ; le fichier local illisible laisse le '
      'sélecteur vide', () async {
    when(
      () => get(any(), month: any(named: 'month')),
    ).thenAnswer((_) async => const Left(NotFoundFailure('agent')));
    final cubit = build();
    await cubit.load();

    expect(cubit.state.status, HrPresenceAgentMonthStatus.failure);
    expect(cubit.state.failure, isA<NotFoundFailure>());
    expect(cubit.state.members, isEmpty);
  });

  test('les agents du fichier local nourrissent le sélecteur', () async {
    when(() => source.read()).thenAnswer(
      (_) async => Right(
        StaffFileSnapshot(
          members: [
            member('a-1'),
            member('a-2', lastName: 'Mayala'),
          ],
          documentsByMember: const {},
          documentTypes: const [],
          hasEverSynced: true,
        ),
      ),
    );
    final cubit = build();
    await cubit.load();
    expect(cubit.state.members.map((m) => m.id), ['a-1', 'a-2']);
  });
}
