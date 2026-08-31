import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_money.dart';

StudentCharge _charge({
  required String feeCode,
  required double expected,
  required String currency,
  double paid = 0,
  double paidPending = 0,
}) => StudentCharge(
  id: 'charge-$feeCode-$currency',
  studentId: 'stu-1',
  academicYearId: 'ay-1',
  schoolLevelId: 'lvl-1',
  schoolLevelGroupId: 'grp-1',
  feeTariffId: 'tar-1',
  feeCode: feeCode,
  label: feeCode,
  expectedAmountInCents: expected,
  amountPaidInCents: paid,
  amountPaidPendingInCents: paidPending,
  currency: currency,
  status: StudentChargeStatus.due,
);

/// La **projection** qui alimente la bande KPI et la pastille — pas leur rendu.
///
/// Le test de rendu construit ses sacs à la main : il ne peut donc rien dire de
/// ce regroupement-ci. Sans ces cas, débrancher la devise de la créance passe au
/// vert, et l'écran se remet à annoncer « 9 042 500 USD » pour 425,00 $ et
/// 90 000 FC.
void main() {
  group('regroupement par devise', () {
    test('deux devises restent deux entrées, jamais une somme', () {
      final charges = [
        _charge(feeCode: 'MINERVAL', expected: 42500, currency: 'USD'),
        _charge(feeCode: 'ASSURANCE', expected: 9000000, currency: 'CDF'),
      ];

      expect(
        charges.expectedBag,
        MoneyBag.of(const [Money(9000000, 'CDF'), Money(42500, 'USD')]),
      );
    });

    test('la devise vient de CHAQUE créance, pas de la première', () {
      // La mutation que ce test existe pour attraper : étiqueter tout le sac
      // avec une devise unique.
      final charges = [
        _charge(feeCode: 'MINERVAL', expected: 42500, currency: 'USD'),
        _charge(feeCode: 'ASSURANCE', expected: 9000000, currency: 'CDF'),
      ];

      expect(charges.expectedBag.length, 2);
      expect(charges.expectedBag.amountIn('USD'), const Money(42500, 'USD'));
      expect(charges.expectedBag.amountIn('CDF'), const Money(9000000, 'CDF'));
    });

    test('deux créances de même devise se somment', () {
      final charges = [
        _charge(feeCode: 'MINERVAL', expected: 42500, currency: 'USD'),
        _charge(feeCode: 'INSCRIPTION', expected: 1500, currency: 'USD'),
      ];

      expect(charges.expectedBag.entries, const [Money(44000, 'USD')]);
    });

    test('aucune créance : le sac est VIDE, pas à zéro', () {
      // « Il ne doit rien, dans aucune unité » n'est pas « zéro dollar ».
      expect(const <StudentCharge>[].expectedBag, MoneyBag.empty);
      expect(const <StudentCharge>[].remainingBag, MoneyBag.empty);
    });
  });

  group('les trois sommes', () {
    test('le payé est COMPOSÉ : miroir serveur + encaissement non remonté', () {
      // FRONT §5 — sans la part locale, un poste soldé le matin hors ligne
      // ressort « aucun paiement » l'après-midi.
      final charges = [
        _charge(
          feeCode: 'MINERVAL',
          expected: 42500,
          currency: 'USD',
          paid: 10000,
          paidPending: 2500,
        ),
      ];

      expect(charges.paidTotalBag.entries, const [Money(12500, 'USD')]);
      expect(charges.remainingBag.entries, const [Money(30000, 'USD')]);
    });

    test('le reste est borné à zéro, devise par devise', () {
      final charges = [
        _charge(
          feeCode: 'MINERVAL',
          expected: 1000,
          currency: 'USD',
          paid: 5000,
        ),
        _charge(feeCode: 'ASSURANCE', expected: 9000000, currency: 'CDF'),
      ];

      // Le trop-perçu en dollars ne vient PAS effacer la dette en francs.
      expect(charges.remainingBag.amountIn('USD'), const Money(0, 'USD'));
      expect(charges.remainingBag.amountIn('CDF'), const Money(9000000, 'CDF'));
    });

    test('une devise soldée disparaît de la pastille, pas des cartes', () {
      final charges = [
        _charge(
          feeCode: 'MINERVAL',
          expected: 42500,
          currency: 'USD',
          paid: 42500,
        ),
        _charge(feeCode: 'ASSURANCE', expected: 9000000, currency: 'CDF'),
      ];

      expect(charges.remainingBag.length, 2);
      expect(charges.remainingBag.withoutZeros.entries, const [
        Money(9000000, 'CDF'),
      ]);
    });
  });

  group('les montants sont des doubles côté entité', () {
    test('l\'arrondi ferme le trou plutôt que la troncature', () {
      // 80,07 vaut 80.069999… en binaire : tronquer emporterait le centime.
      final charges = [
        _charge(feeCode: 'MINERVAL', expected: 8007, currency: 'USD'),
      ];

      expect(charges.expectedBag.entries, const [Money(8007, 'USD')]);
    });
  });
}
