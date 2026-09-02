import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_item_models.dart';

void main() {
  ParentItemValue value({required String phone}) => ParentItemValue(
    firstName: 'Sarah',
    lastName: 'Moke',
    surname: '',
    phoneNumber: phone,
    email: '',
    relationshipType: RelationshipType.mother,
  );

  group('ParentItemValue.isPhoneAcceptable', () {
    test('exige un numéro complet dès qu\'il est ENTAMÉ', () {
      expect(ParentItemValue.isPhoneAcceptable('+243816939060'), isTrue);
      expect(ParentItemValue.isPhoneAcceptable('+24381693'), isFalse);
    });

    /// Depuis la V117, un tuteur sans numéro existe : le parent qui n'a pas de
    /// ligne, celui qui vient inscrire l'enfant d'un frère. L'exigence ne
    /// laissait qu'une issue à l'opérateur — en inventer un — c'est-à-dire une
    /// saisie fausse, et un message envoyé à un inconnu le jour où l'école
    /// notifie.
    test('un champ VIDE est acceptable : ne rien mettre est une décision', () {
      expect(ParentItemValue.isPhoneAcceptable(''), isTrue);
      expect(ParentItemValue.isPhoneAcceptable('   '), isTrue);
    });

    test(
      'laisse passer une valeur héritée tant qu\'elle n\'est pas touchée',
      () {
        // Fiche rattachée par recherche : les champs d'identité sont
        // verrouillés, exiger le format figerait l'inscription sans recours.
        expect(
          ParentItemValue.isPhoneAcceptable(
            '+24381693',
            initialPhone: '+24381693',
          ),
          isTrue,
        );
      },
    );

    test('redevient exigeante dès que l\'utilisateur modifie le numéro', () {
      expect(
        ParentItemValue.isPhoneAcceptable(
          '+2438169390',
          initialPhone: '+24381693',
        ),
        isFalse,
      );
    });

    test('un numéro vidé est accepté, hérité vide ou non', () {
      expect(ParentItemValue.isPhoneAcceptable('', initialPhone: ''), isTrue);
      expect(
        ParentItemValue.isPhoneAcceptable('', initialPhone: '+243816939060'),
        isTrue,
      );
    });
  });

  group('ParentItemValue.isValidAgainst', () {
    test('une fiche chargée avec un numéro hérité reste valide', () {
      final loaded = value(phone: '081693');
      expect(loaded.isValidAgainst(loaded), isTrue);
      expect(loaded.isValid, isTrue);
    });

    test('la même fiche devient invalide une fois le numéro édité', () {
      final initial = value(phone: '081693');
      expect(value(phone: '0816939').isValidAgainst(initial), isFalse);
    });

    test('un numéro complet est valide sans référence à l\'initiale', () {
      expect(value(phone: '+243816939060').isValidAgainst(null), isTrue);
    });
  });
}
