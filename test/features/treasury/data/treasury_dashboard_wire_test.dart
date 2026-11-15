import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';

const _register = {
  'id': 'reg-usd',
  'name': 'Caisse USD',
  'currency': 'USD',
  'inServiceAt': '2026-10-01T06:00:00Z',
  'inServiceOn': '2026-10-01',
  'openingAmountInCents': 522000,
};

void main() {
  test('la vue d ensemble : jour du serveur, année, solde et variation', () {
    final overview = TreasuryWire.overviewFromJson({
      'businessDate': '2026-10-22',
      'academicYear': {
        'id': 'ay-1',
        'name': '2026-2027',
        'startDate': '2026-09-01',
        'endDate': '2027-07-02',
      },
      'registers': [
        {
          'register': _register,
          'balanceInCents': 481900,
          'deltaTodayInCents': -11400,
          'last8Days': [
            {'day': '2026-10-21', 'balanceInCents': 493300, 'closed': true},
            {'day': '2026-10-22', 'balanceInCents': 481900, 'closed': false},
          ],
          'todayClosure': null,
        },
      ],
    });
    expect(overview.businessDate, DateTime(2026, 10, 22));
    expect(overview.academicYear.name, '2026-2027');
    final usd = overview.registers.single;
    expect(usd.balanceInCents, 481900);
    expect(usd.deltaTodayInCents, -11400);
    expect(usd.last8Days.first.closed, isTrue);
    expect(usd.todayClosure, isNull);
  });

  test('l évolution : granularité du serveur, tranche à venir sans solde', () {
    final evolution = TreasuryWire.evolutionFromJson({
      'period': 'MONTH',
      'from': '2026-10-01',
      'to': '2026-10-31',
      'granularity': 'WEEK',
      'cashDays': 19,
      'series': [
        {
          'register': _register,
          'synthesis': {
            'openingInCents': 522000,
            'inflowsInCents': 614000,
            'outflowsInCents': 654000,
            'gapsInCents': 0,
            'closingInCents': 482000,
            'variationPercent': -8,
          },
          'points': [
            {
              'start': '2026-10-25T23:00:00Z',
              'end': '2026-10-31T23:00:00Z',
              'balanceInCents': null,
              'inflowsInCents': 0,
              'outflowsInCents': 0,
              'gapsInCents': 0,
              'partial': false,
            },
          ],
        },
      ],
    });
    expect(evolution.granularity, EvolutionGranularity.week);
    expect(evolution.cashDays, 19);
    final series = evolution.series.single;
    expect(series.synthesis.variationPercent, -8);
    expect(series.points.single.balanceInCents, isNull);
    expect(series.points.single.start, DateTime.utc(2026, 10, 25, 23));
  });
}
