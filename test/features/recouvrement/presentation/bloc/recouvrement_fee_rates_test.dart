import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_fee_rates.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_rate.dart';

void main() {
  LocalRecoveryLine line(
    String studentId, {
    required List<(String feeCode, String currency, int expected, int paid)>
    charges,
  }) => LocalRecoveryLine(
    schoolLevelId: 'lvl-1',
    studentId: studentId,
    charges: [
      for (final (feeCode, currency, expected, paid) in charges)
        RecoveryChargePosition(
          feeCode: feeCode,
          position: FeeChargePosition(
            currency: currency,
            expectedInCents: expected,
            paidMirrorInCents: paid,
            paidPendingInCents: 0,
          ),
        ),
    ],
  );

  group('la règle du taux', () {
    test('(attendu − reste) / attendu, jamais perçu / attendu', () {
      // 100 attendus, 120 perçus dont 20 d'un arriéré : le reste vaut 0.
      expect(
        RecoveryRate.of(expectedInCents: 10000, remainingInCents: 0),
        100,
        reason: 'perçu / attendu vaudrait 120 %',
      );
    });

    test('rien d\'attendu ⇒ 100, et l\'écran doit poser un tiret', () {
      expect(RecoveryRate.of(expectedInCents: 0, remainingInCents: 0), 100);
      expect(RecoveryRate.hasNoExpectation(0), isTrue);
      expect(RecoveryRate.hasNoExpectation(1), isFalse);
    });

    test('arrondi à l\'entier, jamais tronqué', () {
      // 2 soldés sur 3 = 66,67 %
      expect(
        RecoveryRate.of(expectedInCents: 30000, remainingInCents: 10000),
        67,
      );
    });

    test('rien de payé ⇒ 0', () {
      expect(
        RecoveryRate.of(expectedInCents: 30000, remainingInCents: 30000),
        0,
      );
    });
  });

  group('le groupement par devise', () {
    test('un groupe par devise, triés par code croissant', () {
      final groups = RecouvrementFeeRatesProjector.project([
        line(
          's1',
          charges: [
            ('TUITION', 'USD', 30000, 12000),
            ('REGISTRATION', 'CDF', 5000000, 1000000),
          ],
        ),
      ]);

      expect(groups.map((g) => g.currency), ['CDF', 'USD']);
    });

    test('les montants ne traversent jamais une devise', () {
      final groups = RecouvrementFeeRatesProjector.project([
        line(
          's1',
          charges: [
            ('TUITION', 'USD', 30000, 12000),
            ('REGISTRATION', 'CDF', 5000000, 1000000),
          ],
        ),
      ]);

      final usd = groups.firstWhere((g) => g.currency == 'USD');
      final cdf = groups.firstWhere((g) => g.currency == 'CDF');
      expect(usd.expectedInCents, 30000);
      expect(cdf.expectedInCents, 5000000);
    });

    test('un registre vide ne rend AUCUN groupe, pas un groupe vide', () {
      expect(RecouvrementFeeRatesProjector.project(const []), isEmpty);
    });
  });

  group('les postes du groupe', () {
    test('triés par attendu décroissant — ce qui pèse d\'abord', () {
      final groups = RecouvrementFeeRatesProjector.project([
        line(
          's1',
          charges: [
            ('BOOKS', 'USD', 10000, 0),
            ('TUITION', 'USD', 100000, 0),
            ('CLUB', 'USD', 50000, 0),
          ],
        ),
      ]);

      expect(groups.single.fees.map((f) => f.feeCode), [
        'TUITION',
        'CLUB',
        'BOOKS',
      ]);
      expect(groups.single.heaviestExpectedInCents, 100000);
    });

    test('à attendu égal, le code départage — l\'ordre est STABLE', () {
      final groups = RecouvrementFeeRatesProjector.project([
        line(
          's1',
          charges: [('ZZZ', 'USD', 10000, 0), ('AAA', 'USD', 10000, 0)],
        ),
      ]);

      expect(groups.single.fees.map((f) => f.feeCode), ['AAA', 'ZZZ']);
    });

    test('les élèves se cumulent poste par poste', () {
      final groups = RecouvrementFeeRatesProjector.project([
        line('s1', charges: [('TUITION', 'USD', 30000, 12000)]),
        line('s2', charges: [('TUITION', 'USD', 30000, 30000)]),
        line('s3', charges: [('TUITION', 'USD', 30000, 0)]),
      ]);

      final tuition = groups.single.fees.single;
      expect(tuition.expectedInCents, 90000);
      expect(tuition.paidInCents, 42000);
      expect(tuition.remainingInCents, 48000);
      expect(tuition.rate, 47);
    });

    test(
      'un poste SANS attendu est conservé : il porte peut-être un versement',
      () {
        final groups = RecouvrementFeeRatesProjector.project([
          line(
            's1',
            charges: [
              ('TUITION', 'USD', 30000, 0),
              ('DONATION', 'USD', 0, 5000),
            ],
          ),
        ]);

        final donation = groups.single.fees.firstWhere(
          (f) => f.feeCode == 'DONATION',
        );
        expect(donation.paidInCents, 5000);
        expect(
          donation.hasNoExpectation,
          isTrue,
          reason: 'l\'écran posera un tiret, pas un « 100 % » triomphant',
        );
      },
    );
  });

  group('le trop-perçu', () {
    test('ne fait jamais franchir 100 % au taux du poste', () {
      final groups = RecouvrementFeeRatesProjector.project([
        line('s1', charges: [('TUITION', 'USD', 30000, 45000)]),
      ]);

      final tuition = groups.single.fees.single;
      expect(tuition.paidInCents, 45000);
      expect(tuition.remainingInCents, 0);
      expect(tuition.rate, 100);
    });

    test(
      'et n\'efface pas l\'impayé du poste voisin dans le taux du GROUPE',
      () {
        final groups = RecouvrementFeeRatesProjector.project([
          line(
            's1',
            charges: [
              ('TUITION', 'USD', 30000, 40000),
              ('BOOKS', 'USD', 10000, 0),
            ],
          ),
        ]);

        final group = groups.single;
        expect(group.expectedInCents, 40000);
        expect(group.paidInCents, 40000);
        expect(
          group.remainingInCents,
          10000,
          reason: 'le reste est planché POSTE par POSTE',
        );
        expect(
          group.rate,
          75,
          reason: 'perçu / attendu aurait dit 100 %, et ce serait faux',
        );
      },
    );
  });
}
