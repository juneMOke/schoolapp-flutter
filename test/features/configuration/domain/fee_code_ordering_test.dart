import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_code_ordering.dart';

List<FeeCodeOption> _served(List<String> codes) => [
  for (final code in codes) FeeCodeOption(code: code, label: code),
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
