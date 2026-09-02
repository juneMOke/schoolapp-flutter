import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/charge_cascade_allocation.dart';

/// La répartition en cascade (GE-0) — le cœur money-grade de l'encaissement
/// groupé.
///
/// Ce fichier ne cherche pas à montrer que la ventilation est jolie : il
/// établit qu'elle **retombe sur le centime**, pour tout montant et toute forme
/// de groupe. C'est la seule propriété qui compte, parce que c'est la première
/// fois qu'un montant tapé par le caissier n'atterrit pas tel quel sur une
/// créance.
void main() {
  int sum(List<int> values) => values.fold(0, (a, b) => a + b);

  group('la cascade remplit dans l\'ordre reçu', () {
    test('solde les premières tranches, pose le reste sur la suivante', () {
      final result = cascadeAllocation(
        amountInCents: 120000,
        remainingInCents: const [50000, 50000, 50000],
      );

      expect(result, [50000, 50000, 20000]);
    });

    test('n\'atteint pas les tranches au-delà du montant', () {
      final result = cascadeAllocation(
        amountInCents: 30000,
        remainingInCents: const [50000, 50000, 50000],
      );

      expect(result, [30000, 0, 0]);
    });

    test('ne re-trie RIEN : l\'ordre reçu est celui du DAO', () {
      // Si la fonction triait par montant, elle imputerait sur une autre
      // échéance que celle que la fiche annonce.
      final result = cascadeAllocation(
        amountInCents: 60000,
        remainingInCents: const [10000, 90000, 5000],
      );

      expect(result, [10000, 50000, 0]);
    });
  });

  group('L\'INVARIANT : la somme retombe au centime', () {
    // Balayage exhaustif plutôt que trois exemples heureux : c'est le seul
    // niveau de preuve qui vaille sur de l'argent réparti.
    const remainings = [50000, 50000, 50000];
    const cap = 150000;

    test('pour TOUT montant de 0 au-delà du plafond', () {
      for (var amount = 0; amount <= cap + 5000; amount += 1) {
        final result = cascadeAllocation(
          amountInCents: amount,
          remainingInCents: remainings,
        );

        expect(
          sum(result),
          amount < cap ? amount : cap,
          reason: 'montant $amount : la somme des imputations a dérivé',
        );
        for (var i = 0; i < result.length; i++) {
          expect(
            result[i] <= remainings[i],
            isTrue,
            reason: 'montant $amount : la tranche $i dépasse son restant',
          );
          expect(result[i] >= 0, isTrue, reason: 'montant $amount : négatif');
        }
      }
    });

    test('sur des restants irréguliers, y compris à 1 centime', () {
      const irregular = [1, 99999, 7, 250000, 3];
      final cap = cascadeCapInCents(irregular);

      for (var amount = 0; amount <= cap + 10; amount += 7) {
        final result = cascadeAllocation(
          amountInCents: amount,
          remainingInCents: irregular,
        );

        expect(sum(result), amount < cap ? amount : cap);
        for (var i = 0; i < result.length; i++) {
          expect(result[i] <= irregular[i], isTrue);
        }
      }
    });
  });

  group('les bords', () {
    test('un montant nul ou négatif ne distribue rien', () {
      expect(
        cascadeAllocation(
          amountInCents: 0,
          remainingInCents: const [50000, 50000],
        ),
        [0, 0],
      );
      expect(
        cascadeAllocation(amountInCents: -1, remainingInCents: const [50000]),
        [0],
      );
    });

    test('un montant supérieur au total plafonne, sans déborder', () {
      final result = cascadeAllocation(
        amountInCents: 999999,
        remainingInCents: const [50000, 30000],
      );

      expect(result, [50000, 30000]);
      expect(sum(result), 80000);
    });

    test('un restant nul GARDE sa place dans le résultat', () {
      // L'alignement index par index est ce qui empêche d'imputer sur la
      // mauvaise créance : escamoter la tranche soldée décalerait tout.
      final result = cascadeAllocation(
        amountInCents: 60000,
        remainingInCents: const [0, 50000, 0, 50000],
      );

      expect(result, [0, 50000, 0, 10000]);
      expect(result, hasLength(4));
    });

    test('un restant négatif — ligne sale du grand-livre — vaut zéro', () {
      final result = cascadeAllocation(
        amountInCents: 10000,
        remainingInCents: const [-500, 10000],
      );

      expect(result, [0, 10000]);
    });

    test('aucune tranche : rien à répartir, pas d\'exception', () {
      expect(
        cascadeAllocation(amountInCents: 50000, remainingInCents: const []),
        isEmpty,
      );
    });

    test('un centime se pose sur la première tranche atteignable', () {
      expect(
        cascadeAllocation(amountInCents: 1, remainingInCents: const [0, 50000]),
        [0, 1],
      );
    });
  });

  group('cascadeCapInCents', () {
    test('somme ce que les tranches peuvent absorber', () {
      expect(cascadeCapInCents(const [50000, 30000, 20000]), 100000);
    });

    test('ignore les restants nuls et négatifs', () {
      expect(cascadeCapInCents(const [50000, 0, -900, 20000]), 70000);
    });

    test('rien à absorber sur une liste vide', () {
      expect(cascadeCapInCents(const []), 0);
    });

    test('c\'est exactement le plafond de la cascade', () {
      const remainings = [7, 0, 123456, -1, 99];
      final cap = cascadeCapInCents(remainings);

      final saturated = cascadeAllocation(
        amountInCents: cap + 1000,
        remainingInCents: remainings,
      );

      expect(sum(saturated), cap);
    });
  });
}
