import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_pending_probe.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';

import '../../treasury_fixtures.dart';

class _MockRepository extends Mock implements TreasuryDayRepository {}

class _MockProbe extends Mock implements CashPendingProbe {}

void main() {
  late _MockRepository repo;
  late _MockProbe probe;
  late CashClosingCubit cubit;

  setUpAll(() {
    registerFallbackValue(TreasuryCurrency.usd);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = _MockRepository();
    probe = _MockProbe();
    when(() => probe.pendingFor(any())).thenAnswer((_) async => 0);
    cubit = CashClosingCubit(repo, probe, initialDate: demoDay);
  });
  tearDown(() => cubit.close());

  test(
    'aujourd hui : la journée et les envois en attente par devise',
    () async {
      when(
        () => repo.day(demoDay),
      ).thenAnswer((_) async => Right(treasuryDay([usdDay(), cdfDay()])));
      when(
        () => probe.pendingFor(TreasuryCurrency.usd),
      ).thenAnswer((_) async => 2);
      await cubit.load();
      expect(cubit.state.status, CashClosingStatus.ready);
      expect(cubit.state.pendingSync, {
        TreasuryCurrency.usd: 2,
        TreasuryCurrency.cdf: 0,
      });
    },
  );

  test('un jour passé : on ne sonde pas les envois', () async {
    final past = DateTime(2026, 10, 21);
    await cubit.close();
    cubit = CashClosingCubit(repo, probe, initialDate: past);
    when(
      () => repo.day(past),
    ).thenAnswer((_) async => Right(treasuryDay([usdDay()], date: past)));
    await cubit.load();
    expect(cubit.state.pendingSync, isEmpty);
    verifyNever(() => probe.pendingFor(any()));
  });

  test('‹ depuis le lundi : le samedi, jamais le dimanche', () async {
    final monday = DateTime(2026, 10, 19);
    final saturday = DateTime(2026, 10, 17);
    await cubit.close();
    cubit = CashClosingCubit(repo, probe, initialDate: monday);
    when(() => repo.day(any())).thenAnswer(
      (invocation) async => Right(
        treasuryDay([
          usdDay(),
        ], date: invocation.positionalArguments.first as DateTime),
      ),
    );
    await cubit.load();
    await cubit.step(-1);
    expect(cubit.state.date, saturday);
  });

  test('clôturer : refus ou succès, la journée est relue', () async {
    when(
      () => repo.day(demoDay),
    ).thenAnswer((_) async => Right(treasuryDay([usdDay()])));
    when(
      () => repo.close(
        any(),
        id: any(named: 'id'),
        registerId: any(named: 'registerId'),
        matches: any(named: 'matches'),
        shownExpectedInCents: any(named: 'shownExpectedInCents'),
        declaredAmountInCents: any(named: 'declaredAmountInCents'),
        justification: any(named: 'justification'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        TreasuryRefusalFailure(
          TreasuryRefusal.expectedChanged,
          details: {'expectedInCents': 483900},
        ),
      ),
    );
    await cubit.load();
    final result = await cubit.closeRegister(
      id: 'u1',
      registerId: 'reg-usd',
      matches: true,
      shownExpectedInCents: 481900,
    );
    expect(result.isLeft(), isTrue);
    verify(() => repo.day(demoDay)).called(2);
  });

  test('clôturer avec succès : la journée relue arrive à l écran', () async {
    final closed = treasuryDay([usdDay(closure: closedWithGap)]);
    var calls = 0;
    when(() => repo.day(demoDay)).thenAnswer(
      (_) async => Right(calls++ == 0 ? treasuryDay([usdDay()]) : closed),
    );
    when(
      () => repo.close(
        any(),
        id: any(named: 'id'),
        registerId: any(named: 'registerId'),
        matches: any(named: 'matches'),
        shownExpectedInCents: any(named: 'shownExpectedInCents'),
        declaredAmountInCents: any(named: 'declaredAmountInCents'),
        justification: any(named: 'justification'),
      ),
    ).thenAnswer((_) async => Right(closedWithGap));
    await cubit.load();
    final result = await cubit.closeRegister(
      id: 'u1',
      registerId: 'reg-usd',
      matches: true,
      shownExpectedInCents: 481900,
    );
    expect(result.isRight(), isTrue);
    expect(cubit.state.day, closed);
  });

  test('ouvert un dimanche : on part du lundi, comme le serveur', () async {
    await cubit.close();
    cubit = CashClosingCubit(repo, probe, initialDate: DateTime(2026, 10, 25));
    expect(cubit.state.date, DateTime(2026, 10, 26));
  });

  test(
    'INVALID_DATE (horloge de tablette en avance) : on se recale sur le jour '
    'que le serveur donne',
    () async {
      final ahead = DateTime(2026, 10, 23);
      await cubit.close();
      cubit = CashClosingCubit(repo, probe, initialDate: ahead);
      when(() => repo.day(ahead)).thenAnswer(
        (_) async => const Left(
          TreasuryRefusalFailure(
            TreasuryRefusal.invalidDate,
            details: {'businessDate': '2026-10-22'},
          ),
        ),
      );
      when(
        () => repo.day(demoDay),
      ).thenAnswer((_) async => Right(treasuryDay([usdDay()])));
      await cubit.load();
      expect(cubit.state.date, demoDay);
      expect(cubit.state.status, CashClosingStatus.ready);
    },
  );

  test(
    'une relecture lente ne ramène pas l écran sur la journée qu on a quittée',
    () async {
      final saturday = DateTime(2026, 10, 17);
      final monday = DateTime(2026, 10, 19);
      await cubit.close();
      cubit = CashClosingCubit(repo, probe, initialDate: monday);
      final slow = Completer<Either<Failure, TreasuryDay>>();
      var mondayCalls = 0;
      when(() => repo.day(monday)).thenAnswer(
        (_) => mondayCalls++ == 0
            ? Future.value(
                Right(
                  treasuryDay([usdDay()], date: monday, businessDate: monday),
                ),
              )
            : slow.future,
      );
      when(() => repo.day(saturday)).thenAnswer(
        (_) async => Right(
          treasuryDay([usdDay()], date: saturday, businessDate: monday),
        ),
      );
      await cubit.load();
      final refreshing = cubit.refresh(); // après un geste, sur lundi
      await cubit.step(-1); // l'utilisatrice part sur samedi
      slow.complete(
        Right(treasuryDay([usdDay()], date: monday, businessDate: monday)),
      );
      await refreshing;
      expect(cubit.state.date, saturday);
      expect(cubit.state.day?.date, saturday);
    },
  );

  test(
    'une journée qui échoue garde la navigation : on peut toujours en sortir',
    () async {
      final saturday = DateTime(2026, 10, 17);
      final monday = DateTime(2026, 10, 19);
      await cubit.close();
      cubit = CashClosingCubit(repo, probe, initialDate: monday);
      when(() => repo.day(monday)).thenAnswer(
        (_) async =>
            Right(treasuryDay([usdDay()], date: monday, businessDate: monday)),
      );
      when(
        () => repo.day(saturday),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      await cubit.load();
      await cubit.step(-1);
      expect(cubit.state.status, CashClosingStatus.failure);
      expect(cubit.state.businessDate, monday);
      expect(cubit.nextDay(1), monday);
    },
  );

  test('une relecture ratée ne vide pas l écran', () async {
    var calls = 0;
    when(() => repo.day(demoDay)).thenAnswer(
      (_) async => calls++ == 0
          ? Right(treasuryDay([usdDay()]))
          : const Left(NetworkFailure()),
    );
    await cubit.load();
    await cubit.refresh();
    expect(cubit.state.status, CashClosingStatus.ready);
    expect(cubit.state.day, isNotNull);
  });
}
