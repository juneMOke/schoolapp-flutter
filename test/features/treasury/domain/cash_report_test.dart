import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

void main() {
  group('les ids recalculés suivent le contrat', () {
    test('journalier', () {
      expect(CashReportIds.daily(DateTime(2026, 10, 22)), 'RJ-20261022');
    });

    test('hebdomadaire, fin à 4 chiffres dans l année', () {
      expect(
        CashReportIds.weekly(DateTime(2026, 10, 19), DateTime(2026, 10, 24)),
        'RH-20261019-1024',
      );
    });

    test('une semaine qui passe le Nouvel An écrit sa fin en entier', () {
      expect(
        CashReportIds.weekly(DateTime(2026, 12, 28), DateTime(2027, 1, 2)),
        'RH-20261228-20270102',
      );
    });

    test('décembre reste court : un mois ne traverse jamais l année', () {
      expect(
        CashReportIds.monthly(DateTime(2026, 12), DateTime(2026, 12, 31)),
        'RM-20261201-1231',
      );
    });
  });

  test(
    'un rapport et sa page se décodent ; une devise inconnue est ignorée',
    () {
      final page = TreasuryWire.reportPageFromJson({
        'content': [
          {
            'id': 'RH-20261019-1024',
            'kind': 'WEEKLY',
            'from': '2026-10-19',
            'to': '2026-10-24',
            'title': 'Semaine du 19 oct. au 24 oct. 2026',
            'status': 'PROVISIONAL',
            'inProgress': true,
            'currencies': ['USD', 'EUR', 'CDF'],
          },
        ],
        'totalElements': 9,
        'totalPages': 2,
        'number': 1,
        'size': 8,
      });
      expect(page.number, 1);
      expect(page.totalPages, 2);
      final report = page.items.single;
      expect(report.kind, CashReportKind.weekly);
      expect(report.isFinal, isFalse);
      expect(report.to, DateTime(2026, 10, 24));
      expect(report.currencies, [TreasuryCurrency.usd, TreasuryCurrency.cdf]);
    },
  );
}
