import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/load_journal_day_use_case.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_change_source.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_state.dart';

class _MockLoad extends Mock implements LoadJournalDayUseCase {}

class _MockSource extends Mock implements JournalChangeSource {}

void main() {
  late _MockLoad load;
  late _MockSource source;
  late void Function() signal;
  final today = DateTime(2026, 10, 14);
  final year = AcademicYear(
    id: 'ay',
    name: '2026-2027',
    startDate: DateTime(2026, 10, 13),
    endDate: DateTime(2026, 10, 15),
    current: true,
  );

  JournalDay dayOn(DateTime date) => JournalDay(date: date, lines: const []);

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(year);
  });

  setUp(() {
    load = _MockLoad();
    source = _MockSource();
    when(() => load.today()).thenReturn(today);
    when(() => source.pull()).thenAnswer((_) async {});
    when(() => source.watch(any())).thenAnswer((invocation) {
      signal = invocation.positionalArguments.single as void Function();
      return () {};
    });
    when(() => load(any(), year: any(named: 'year'))).thenAnswer(
      (invocation) async =>
          Right(dayOn(invocation.positionalArguments.single as DateTime)),
    );
  });

  JournalDayCubit build() => JournalDayCubit(load: load, source: source);

  test('ouvre aujourd\'hui, tire ses flux et écoute les signaux', () async {
    final cubit = build();
    await cubit.start(year);

    expect(cubit.state, isA<JournalDayReady>());
    expect(cubit.state.isToday, isTrue);
    verify(() => source.pull()).called(1);
    await cubit.close();
  });

  test('navigation jour par jour, bornée par l\'année', () async {
    final cubit = build();
    await cubit.start(year);

    await cubit.previous();
    expect(cubit.state.date, DateTime(2026, 10, 13));
    expect(cubit.canGoBack, isFalse);
    await cubit.previous();
    expect(cubit.state.date, DateTime(2026, 10, 13));

    await cubit.next();
    await cubit.next();
    expect(cubit.state.date, DateTime(2026, 10, 15));
    expect(cubit.canGoForward, isFalse);

    await cubit.goToday();
    expect(cubit.state.date, today);
    await cubit.close();
  });

  test('une relecture en échec garde la page affichée', () async {
    final cubit = build();
    await cubit.start(year);
    when(
      () => load(any(), year: any(named: 'year')),
    ).thenAnswer((_) async => const Left(StorageFailure('ko')));

    signal();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<JournalDayReady>());
    await cubit.close();
  });

  test('un échec à l\'ouverture d\'un jour s\'affiche', () async {
    when(
      () => load(any(), year: any(named: 'year')),
    ).thenAnswer((_) async => const Left(StorageFailure('ko')));
    final cubit = build();

    await cubit.start(year);

    expect(cubit.state, isA<JournalDayFailure>());
    await cubit.close();
  });

  test('une lecture dépassée par une navigation est ignorée', () async {
    final slow = Completer<Either<Failure, JournalDay>>();
    final cubit = build();
    await cubit.start(year);
    when(
      () => load(DateTime(2026, 10, 13), year: any(named: 'year')),
    ).thenAnswer((_) => slow.future);

    final back = cubit.previous();
    await cubit.next();
    slow.complete(Right(dayOn(DateTime(2026, 10, 13))));
    await back;

    // Le 13 s'affichait déjà en chargement : « suivant » mène au 14.
    expect(cubit.state.date, today);
    expect(cubit.state, isA<JournalDayReady>());
    await cubit.close();
  });
}
