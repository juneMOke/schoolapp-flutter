import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_code_ordering.dart';

/// Le catalogue d'une école qui n'a rien paramétré : le serveur sert alors les
/// rangs `0, 1, … n-1`, dans cet ordre et sans trou.
List<FeeCodeOption> _served(List<String> codes) => [
  for (final (index, code) in codes.indexed)
    FeeCodeOption(code: code, label: code, sortOrder: index),
];

void main() {
  group('un ordre, jamais un filtre', () {
    test('tout code servi reste atteignable', () {
      // Le front n'applique aucune liste blanche : un code ajouté côté serveur
      // doit apparaître sans release de l'application, ce qui est la seule
      // raison de consommer une route plutôt qu'un fichier.
      final served = _served([
        'TUITION',
        'LAB_FEE',
        'CANTEEN',
        'LIBRARY',
        'SPORTS',
      ]);

      final total =
          FeeCodeOrdering.common(served).length +
          FeeCodeOrdering.others(served).length;

      expect(total, served.length);
    });

    test(
      'un code inconnu de la liste tombe dans « autres », pas dans l\'oubli',
      () {
        final served = _served(['TUITION', 'QUOTA_INTERNET']);

        expect(
          FeeCodeOrdering.others(served).map((o) => o.code),
          contains('QUOTA_INTERNET'),
        );
      },
    );

    test('un code nommé mais plus servi disparaît sans erreur', () {
      // On n'affiche que l'intersection : la liste préférée ne peut pas
      // inventer un type que le serveur refuserait ensuite en 422.
      final served = _served(['TUITION']);

      expect(FeeCodeOrdering.common(served).map((o) => o.code), ['TUITION']);
    });

    test('un catalogue vide ne rend rien, sans lever', () {
      expect(FeeCodeOrdering.common(const []), isEmpty);
      expect(FeeCodeOrdering.others(const []), isEmpty);
    });
  });

  group('mise en tête', () {
    test(
      'les usuels sortent dans l\'ordre de saisie, pas celui du serveur',
      () {
        // Le serveur les sert dans son ordre d'énumération ; l'écran les range
        // dans l'ordre où un directeur les saisit.
        final served = _served(['CANTEEN', 'TUITION', 'REGISTRATION']);

        expect(FeeCodeOrdering.common(served).map((o) => o.code), [
          'REGISTRATION',
          'TUITION',
          'CANTEEN',
        ]);
      },
    );

    test('les autres gardent l\'ordre du serveur', () {
      final served = _served(['SPORTS', 'LAB_FEE', 'LIBRARY']);

      expect(FeeCodeOrdering.others(served).map((o) => o.code), [
        'SPORTS',
        'LAB_FEE',
        'LIBRARY',
      ]);
    });
  });

  group("l'ordre de l'école prime sur la constante locale", () {
    test('une école qui n\'a rien paramétré garde la mise en tête locale', () {
      // Rangs 0,1,2 servis dans l'ordre : rien n'a été décidé, les vingt-trois
      // natures de l'énumération noieraient sinon les trois qu'on saisit.
      final served = _served(['CANTEEN', 'TUITION', 'REGISTRATION']);

      expect(FeeCodeOrdering.isConfigured(served), isFalse);
      expect(FeeCodeOrdering.common(served).first.code, 'REGISTRATION');
    });

    test('un rang choisi fait tout basculer dans l\'ordre servi', () {
      // La cantine hissée en tête : la reléguer derrière « Autres types »
      // défaisait sous les yeux du directeur ce qu'il venait de décider.
      const served = [
        FeeCodeOption(code: 'CANTEEN', label: 'Cantine', sortOrder: 0),
        FeeCodeOption(code: 'TUITION', label: 'Minerval', sortOrder: 0),
        FeeCodeOption(code: 'LAB_FEE', label: 'Laboratoire', sortOrder: 11),
      ];

      expect(FeeCodeOrdering.isConfigured(served), isTrue);
      expect(FeeCodeOrdering.common(served).map((o) => o.code), [
        'CANTEEN',
        'TUITION',
        'LAB_FEE',
      ]);
      expect(FeeCodeOrdering.others(served), isEmpty);
    });

    test('une section masquée laisse un trou, qui suffit à le voir', () {
      // Le serveur ne sert pas les masquées : le rang saute, et c'est le seul
      // signe qu'une décision a été prise — aucun champ supplémentaire.
      const served = [
        FeeCodeOption(code: 'TUITION', label: 'Minerval', sortOrder: 0),
        FeeCodeOption(code: 'CANTEEN', label: 'Cantine', sortOrder: 5),
      ];

      expect(FeeCodeOrdering.isConfigured(served), isTrue);
    });
  });

  group('montants indicatifs', () {
    test('les usuels en ont un', () {
      for (final code in FeeCodeOrdering.preferred) {
        expect(kIndicativeAmountsInCents[code], isNotNull, reason: code);
      }
    });

    test('les autres ouvrent sur un montant vierge', () {
      // Une aide à la saisie, pas une donnée : inventer un montant pour un
      // type qu'on ne connaît pas serait pire que ne rien proposer.
      expect(kIndicativeAmountsInCents['LAB_FEE'], isNull);
    });
  });
}
