import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_eviction_policy.dart';

/// Politique d'éviction LRU du cache éditique — éprouvée **à vide**, avant
/// qu'un seul octet n'existe sur le disque (lot L3.2).
List<EditiqueCacheFootprint> _entries(List<int> sizes) => [
  for (var i = 0; i < sizes.length; i++)
    EditiqueCacheFootprint(id: 'c-$i', sizeBytes: sizes[i]),
];

void main() {
  // Budget de 1000 octets, cible à 900 : des chiffres ronds pour que les
  // assertions parlent de la règle, pas de l'arithmétique.
  const policy = EditiqueCacheEvictionPolicy(
    budgetBytes: 1000,
    targetRatio: 0.9,
  );

  group('déclenchement', () {
    test('sous le budget, on n\'évince rien', () {
      expect(policy.selectVictims(_entries([300, 300, 300])), isEmpty);
    });

    // Le seuil est un dépassement STRICT : tenir exactement dans le budget est
    // un cas nominal, pas une alerte.
    test('exactement au budget, on n\'évince rien', () {
      expect(policy.selectVictims(_entries([500, 500])), isEmpty);
    });

    test('au-delà du budget, on évince', () {
      expect(policy.selectVictims(_entries([500, 501])), isNotEmpty);
    });

    test('needsSweep suit la même règle stricte', () {
      expect(policy.needsSweep(1000), isFalse);
      expect(policy.needsSweep(1001), isTrue);
    });
  });

  group('choix des victimes', () {
    // La liste est ordonnée du moins récemment utilisé au plus récent : la
    // première entrée part la première.
    test('les moins récemment utilisées partent en premier', () {
      final victims = policy.selectVictims(_entries([200, 200, 200, 200, 400]));

      expect(victims, ['c-0', 'c-1']);
    });

    // On redescend à la CIBLE (900), pas au budget (1000) : sans cette marge,
    // la prochaine écriture redéclencherait aussitôt un balayage.
    test('on redescend sous la cible, pas seulement sous le budget', () {
      final victims = policy.selectVictims(_entries([100, 100, 850]));

      // 1050 → retirer c-0 laisse 950 : sous le budget, mais pas encore sous la
      // cible. Il faut donc aussi c-1.
      expect(victims, ['c-0', 'c-1']);
    });

    test('on n\'évince pas plus que nécessaire', () {
      final victims = policy.selectVictims(_entries([200, 900]));

      expect(victims, ['c-0']);
    });

    // Une pièce plus grosse que le budget entier ne doit pas faire boucler le
    // balayage : il rend simplement tout ce qu'il connaît.
    test('une entrée plus grosse que le budget évince tout', () {
      final victims = policy.selectVictims(_entries([5000]));

      expect(victims, ['c-0']);
    });

    // Des entrées de taille nulle ne libèrent rien : le parcours est borné par
    // la liste, jamais par la quantité libérée.
    test('des tailles nulles ne font pas boucler', () {
      final victims = policy.selectVictims(_entries([0, 0, 0, 1001]));

      expect(victims, ['c-0', 'c-1', 'c-2', 'c-3']);
    });

    // Une taille négative est une ligne aberrante : elle ne doit pas CRÉDITER
    // le budget, ce qui masquerait un dépassement réel.
    test('une taille négative ne crédite pas le budget', () {
      expect(
        EditiqueCacheEvictionPolicy.totalSizeOf(_entries([-500, 900])),
        900,
      );
      expect(policy.selectVictims(_entries([-500, 900])), isEmpty);
    });

    test('un cache vide ne produit aucune victime', () {
      expect(policy.selectVictims(const []), isEmpty);
    });

    test('la liste rendue est immuable', () {
      final victims = policy.selectVictims(_entries([1500]));

      expect(() => victims.add('c-x'), throwsUnsupportedError);
    });
  });

  group('bornes de configuration', () {
    test('un budget nul évince tout', () {
      const zero = EditiqueCacheEvictionPolicy(budgetBytes: 0);

      expect(zero.targetBytes, 0);
      expect(zero.selectVictims(_entries([1, 1])), ['c-0', 'c-1']);
    });

    // Un ratio aberrant ne doit pas vider le cache par accident.
    test('un ratio hors bornes est ramené dans [0, 1]', () {
      const tooHigh = EditiqueCacheEvictionPolicy(
        budgetBytes: 1000,
        targetRatio: 4,
      );
      const negative = EditiqueCacheEvictionPolicy(
        budgetBytes: 1000,
        targetRatio: -1,
      );

      expect(tooHigh.targetBytes, 1000);
      expect(negative.targetBytes, 0);
    });

    test('le défaut vise 2 Gio, cible juste en dessous', () {
      const defaults = EditiqueCacheEvictionPolicy();

      expect(defaults.budgetBytes, 2 * 1024 * 1024 * 1024);
      expect(defaults.targetBytes, lessThan(defaults.budgetBytes));
      // La marge reste faible : une pièce évincée n'est récupérable qu'en
      // ligne, donc on en évince le moins possible à la fois.
      expect(
        defaults.budgetBytes - defaults.targetBytes,
        lessThan(defaults.budgetBytes ~/ 10),
      );
    });
  });
}
