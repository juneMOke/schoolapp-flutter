import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_period_cubit.dart';

import '../../treasury_fixtures.dart';

class _MockRepository extends Mock implements TreasuryDayRepository {}

void main() {
  late _MockRepository repo;

  setUpAll(() => registerFallbackValue(DateTime(2026)));
  setUp(() => repo = _MockRepository());

  CashPeriodCubit cubitAt(DateTime today) => CashPeriodCubit(
    repo,
    scope: ClosingScope.week,
    today: today,
    historyStart: DateTime(2026, 10, 1),
  );

  test('la semaine en cours, demandée du lundi au samedi', () async {
    when(
      () => repo.period(any(), any()),
    ).thenAnswer((_) async => Right(treasuryWeek()));
    final cubit = cubitAt(demoDay);
    addTearDown(cubit.close);
    await cubit.load();
    verify(
      () => repo.period(DateTime(2026, 10, 19), DateTime(2026, 10, 24)),
    ).called(1);
    expect(cubit.state.status, CashPeriodStatus.ready);
    expect(cubit.isCurrent, isTrue);
    expect(cubit.nextFrom(1), isNull);
  });

  test('INVALID_RANGE (horloge en avance) : on se recale sur la semaine du '
      'serveur', () async {
    final ahead = DateTime(2026, 10, 27);
    when(() => repo.period(DateTime(2026, 10, 26), any())).thenAnswer(
      (_) async => const Left(
        TreasuryRefusalFailure(
          TreasuryRefusal.invalidRange,
          details: {'businessDate': '2026-10-22'},
        ),
      ),
    );
    when(
      () => repo.period(DateTime(2026, 10, 19), any()),
    ).thenAnswer((_) async => Right(treasuryWeek()));
    final cubit = cubitAt(ahead);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.from, DateTime(2026, 10, 19));
    expect(cubit.state.status, CashPeriodStatus.ready);
  });

  test('une période se décode, totaux et journées', () {
    final period = TreasuryWire.periodFromJson({
      'from': '2026-10-19',
      'to': '2026-10-24',
      'registers': [
        {
          'register': {
            'id': 'reg-usd',
            'name': 'Caisse USD',
            'currency': 'USD',
            'inServiceAt': '2026-10-01T06:00:00Z',
            'inServiceOn': '2026-10-01',
            'openingAmountInCents': 522000,
          },
          'synthesis': {
            'openingInCents': 536900,
            'inflowsInCents': 92000,
            'outflowsInCents': 147000,
            'gapsInCents': -500,
            'closingInCents': 481400,
            'variationPercent': null,
          },
        },
      ],
      'days': [
        {
          'day': '2026-10-21',
          'cells': [
            {
              'registerId': 'reg-usd',
              'inflowsInCents': 27200,
              'outflowsInCents': 29100,
              'gapInCents': -500,
              'closingBalanceInCents': 492800,
              'status': 'NOT_CLOSED',
              'justification': null,
            },
          ],
        },
      ],
    });
    final s = period.registers.single.synthesis;
    expect(s.gapsInCents, -500);
    expect(s.closingInCents, 481400);
    expect(s.variationPercent, isNull);
    final cell = period.days.single.cellOf('reg-usd')!;
    expect(cell.inflowsInCents, 27200);
    expect(cell.outflowsInCents, 29100);
    expect(cell.closingBalanceInCents, 492800);
  });
}
