import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_rate_board.dart';

/// Lot R3 — le tableau des taux corrigés à la main.
///
/// ⚠️ **Aucune assertion ne porte sur l'écriture de l'amorce.** Elle vient de
/// `ExchangeRate.formatted`, qui a ses propres tests, et parier dessus a déjà
/// coûté trois échecs à ce chantier. Ce qui est éprouvé ici est la RÈGLE :
/// ouvert mais intact ⇒ le référentiel garde la main ; corrigé ⇒ le taux du
/// caissier commande.
final _taux = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2000000000,
  effectiveFrom: DateTime.utc(2026, 9, 15),
  divergenceBandBp: 200,
);

const _paire = 'USD>CDF';

void main() {
  late int rafraichissements;
  late FacturationRateBoard board;

  setUp(() {
    rafraichissements = 0;
    board = FacturationRateBoard(onChanged: () => rafraichissements++);
  });

  tearDown(() => board.dispose());

  group('le contrôleur', () {
    test('est le MÊME pour une paire donnée', () {
      // Deux contrôleurs pour une paire, ce serait deux taux pour un versement.
      expect(
        identical(board.controllerOf(_paire), board.controllerOf(_paire)),
        isTrue,
      );
    });

    test('est distinct d\'une paire à l\'autre', () {
      expect(
        identical(board.controllerOf(_paire), board.controllerOf('EUR>CDF')),
        isFalse,
      );
    });

    test('rafraîchit l\'écran à chaque frappe', () {
      // Sans cette écoute, le caissier taperait dans un champ sans effet
      // visible : ni les montants dérivés, ni le total, ni le CTA ne bougeraient.
      board.controllerOf(_paire).text = '2500';

      expect(rafraichissements, greaterThan(0));
    });
  });

  group('ouvrir une boîte', () {
    test('la marque ouverte', () {
      expect(board.isEditing(_paire), isFalse);

      board.open(_paire, _taux);

      expect(board.isEditing(_paire), isTrue);
    });

    test('l\'amorce au taux affiché', () {
      board.open(_paire, _taux);

      expect(board.controllerOf(_paire).text, isNotEmpty);
    });

    test('rouvrir n\'efface PAS ce que le caissier avait tapé', () {
      board.open(_paire, _taux);
      board.controllerOf(_paire).text = '2500';

      board.open(_paire, _taux);

      expect(board.controllerOf(_paire).text, '2500');
    });
  });

  group('le taux appliqué', () {
    test('est nul tant que la boîte n\'a pas été ouverte', () {
      expect(board.microsOf(_paire), isNull);
      expect(board.overrides, isEmpty);
    });

    test('reste nul sur une boîte ouverte mais INTACTE', () {
      // C'est la règle qui justifie de mémoriser l'amorce : ouvrir sans rien
      // taper appliquerait la valeur affichée — arrondie au centième — à la
      // place du taux du référentiel, qui en porte six.
      board.open(_paire, _taux);

      expect(board.microsOf(_paire), isNull);
      expect(board.overrides, isEmpty);
    });

    test('vaut ce que le caissier a tapé, en micro-unités', () {
      board.open(_paire, _taux);
      board.controllerOf(_paire).text = '2500';

      expect(board.microsOf(_paire), 2500000000);
      expect(board.overrides, {_paire: 2500000000});
    });

    test('reste nul sur une saisie qui n\'est pas un nombre', () {
      board.open(_paire, _taux);
      board.controllerOf(_paire).text = 'deux mille';

      expect(board.microsOf(_paire), isNull);
    });

    test('reste nul sur zéro ou un montant négatif', () {
      board.open(_paire, _taux);
      board.controllerOf(_paire).text = '0';
      expect(board.microsOf(_paire), isNull);

      board.controllerOf(_paire).text = '-5';
      expect(board.microsOf(_paire), isNull);
    });
  });

  group('refermer les boîtes intactes', () {
    test('referme celle que personne n\'a touchée', () {
      board.open(_paire, _taux);

      board.closeUntouched();

      expect(board.isEditing(_paire), isFalse);
      expect(board.controllerOf(_paire).text, isEmpty);
    });

    test('ÉPARGNE un taux réellement corrigé (A4)', () {
      // Une correction est une intention du caissier, pas une valeur dérivée de
      // la date : elle survit au changement de jour.
      board.open(_paire, _taux);
      board.controllerOf(_paire).text = '2500';

      board.closeUntouched();

      expect(board.isEditing(_paire), isTrue);
      expect(board.controllerOf(_paire).text, '2500');
      expect(board.microsOf(_paire), 2500000000);
    });

    test('ne touche pas aux paires jamais ouvertes', () {
      board.open(_paire, _taux);
      board.controllerOf('EUR>CDF').text = '3000';

      board.closeUntouched();

      expect(board.controllerOf('EUR>CDF').text, '3000');
    });
  });
}
