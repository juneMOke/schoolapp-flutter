import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

StudentCharge charge({
  required double expected,
  required double paid,
  String feeTariffId = 't1',
  String label = 'Organisation matériel examens — 2/3',
}) {
  return StudentCharge(
    id: 'c1',
    studentId: 's1',
    academicYearId: 'y1',
    schoolLevelId: 'l1',
    schoolLevelGroupId: 'g1',
    feeTariffId: feeTariffId,
    feeCode: 'TUITION',
    label: label,
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    currency: 'CDF',
    status: StudentChargeStatus.partial,
  );
}

void main() {
  final AppLocalizations l10n = AppLocalizationsFr();

  group('chargeRemainingInCents', () {
    test('retourne attendu − payé', () {
      expect(
        chargeRemainingInCents(charge(expected: 500000, paid: 200000)),
        300000,
      );
    });

    test('jamais négatif', () {
      expect(chargeRemainingInCents(charge(expected: 500000, paid: 600000)), 0);
    });
  });

  group('designatedFeeTariffId', () {
    test('rend la ligne de grille désignée par le frais', () {
      expect(designatedFeeTariffId(charge(expected: 500000, paid: 0)), 't1');
    });

    /// Le pont depuis le grand-livre local replie l'absence de tarif sur `''`,
    /// et c'est cette entité-là que lit le guichet. Envoyer la chaîne vide au
    /// serveur ne serait ni un uuid ni un `null` : il ne saurait pas la lire
    /// comme « créance hors grille », et l'imputation se jouerait sur un repli
    /// que personne n'a demandé.
    test('un frais hors grille ne désigne RIEN, pas une chaîne vide', () {
      expect(
        designatedFeeTariffId(
          charge(expected: 500000, paid: 0, feeTariffId: ''),
        ),
        isNull,
      );
    });
  });

  group('chargeDesignation', () {
    /// La nature seule rend trois lignes identiques dès qu'un niveau porte
    /// plusieurs tranches d'un même frais : trois montants, trois échéances, et
    /// aucun moyen de savoir laquelle on coche — ni laquelle on valide.
    test('nomme LA tranche, pas la famille de frais', () {
      expect(
        chargeDesignation(charge(expected: 500000, paid: 0), l10n),
        'Organisation matériel examens — 2/3',
      );
    });

    /// Une créance *ad hoc* peut n'avoir aucun libellé : un frais sans nom du
    /// tout serait pire que trop générique.
    test('sans libellé, replie sur la nature du frais', () {
      expect(
        chargeDesignation(charge(expected: 500000, paid: 0, label: '  '), l10n),
        l10n.studentChargeFeeCodeTuition,
      );
    });
  });

  group('parseAmountToCents', () {
    test('convertit une saisie valide en cents', () {
      expect(parseAmountToCents('5000'), 500000);
    });

    test('retourne 0 pour vide / invalide / négatif', () {
      expect(parseAmountToCents(''), 0);
      expect(parseAmountToCents('abc'), 0);
      expect(parseAmountToCents('-10'), 0);
    });
  });

  group('effectiveAllocationCents', () {
    test('0 si non cochée', () {
      expect(
        effectiveAllocationCents(
          selected: false,
          rawAmount: '5000',
          remainingInCents: 300000,
        ),
        0,
      );
    });

    test('borné au restant dû quand la saisie dépasse', () {
      expect(
        effectiveAllocationCents(
          selected: true,
          rawAmount: '5000',
          remainingInCents: 300000,
        ),
        300000,
      );
    });

    test('respecte une saisie inférieure au restant', () {
      expect(
        effectiveAllocationCents(
          selected: true,
          rawAmount: '1000',
          remainingInCents: 300000,
        ),
        100000,
      );
    });
  });

  group('isAmountOverflowing', () {
    test('true uniquement quand cochée et saisie > restant', () {
      expect(
        isAmountOverflowing(
          selected: true,
          rawAmount: '5000',
          remainingInCents: 300000,
        ),
        isTrue,
      );
      expect(
        isAmountOverflowing(
          selected: true,
          rawAmount: '2000',
          remainingInCents: 300000,
        ),
        isFalse,
      );
      expect(
        isAmountOverflowing(
          selected: false,
          rawAmount: '5000',
          remainingInCents: 300000,
        ),
        isFalse,
      );
    });
  });
}
