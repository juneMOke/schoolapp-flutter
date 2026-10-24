import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';

import '../../hr_presence_builders.dart';

class _MockMonth extends Mock implements GetHrAttendanceAgentMonthUseCase {}

class _MockYear extends Mock implements GetHrAttendanceAgentYearUseCase {}

class _MockSource extends Mock implements StaffSnapshotSource {}

void main() {
  late _MockMonth month;
  late _MockYear year;

  setUp(() {
    month = _MockMonth();
    year = _MockYear();
    when(
      () => month(any(), month: any(named: 'month')),
    ).thenAnswer((_) async => Right(agentMonthOf()));
    when(() => year(any())).thenAnswer((_) async => Right(agentYearOf()));
  });

  HrPresenceFicheCubit build({bool yearly = false, String? asked}) {
    final source = _MockSource();
    when(
      () => source.read(),
    ).thenAnswer((_) async => const Left(StorageFailure('—')));
    final cubit = HrPresenceFicheCubit(
      getMonth: month,
      getYear: year,
      source: source,
      args: (
        agentId: 'a-1',
        yearly: yearly,
        month: asked,
        yearStart: DateTime(2026, 9, 1),
      ),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test(
    'la vue annuelle lit l\'année ; un mois l\'ouvre en vue mensuelle',
    () async {
      final cubit = build(yearly: true);
      await cubit.load();
      verify(() => year('a-1')).called(1);
      expect(cubit.state.yearData, isNotNull);

      await cubit.openMonth('2026-09');
      expect(cubit.state.yearly, isFalse);
      expect(cubit.state.yearData, isNull);
      verify(() => month('a-1', month: '2026-09')).called(1);
    },
  );

  test('la vue mensuelle, puis l\'année : le mois est gardé', () async {
    final cubit = build(asked: '2026-09');
    await cubit.load();
    verify(() => month('a-1', month: '2026-09')).called(1);
    await cubit.setYearly(true);
    expect(cubit.state.month, '2026-09');
    await cubit.setYearly(false);
    verify(() => month('a-1', month: '2026-09')).called(1);
  });

  test('changer d\'agent garde la portée', () async {
    final cubit = build(yearly: true);
    await cubit.load();
    await cubit.openAgent('a-2');
    verify(() => year('a-2')).called(1);
  });
}
