import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';

void main() {
  group('PhoneNumberFormat.nationalPartOf', () {
    test('laisse intacte une partie nationale déjà propre', () {
      expect(PhoneNumberFormat.nationalPartOf('816939060'), '816939060');
    });

    test('retire un indicatif E.164', () {
      expect(PhoneNumberFormat.nationalPartOf('+243816939060'), '816939060');
    });

    test('retire un indicatif écrit 00243', () {
      expect(PhoneNumberFormat.nationalPartOf('00243816939060'), '816939060');
    });

    test('retire le 0 du plan national', () {
      expect(PhoneNumberFormat.nationalPartOf('0816939060'), '816939060');
    });

    test('ignore les séparateurs de mise en forme', () {
      expect(
        PhoneNumberFormat.nationalPartOf('+243 (81) 693-90 60'),
        '816939060',
      );
    });

    test('retire l\'indicatif d\'une bribe préfixée d\'un + explicite', () {
      // Recherche par bribe : le champ produit "+2438169" pour "8169".
      expect(PhoneNumberFormat.nationalPartOf('+2438169'), '8169');
    });

    test('ne mutile pas une bribe nue commençant comme l\'indicatif', () {
      expect(PhoneNumberFormat.nationalPartOf('2438169'), '2438169');
    });

    test('rend une chaîne vide quand il n\'y a aucun chiffre', () {
      expect(PhoneNumberFormat.nationalPartOf('  +  '), '');
    });
  });

  group('PhoneNumberFormat.toE164', () {
    test('recompose l\'indicatif devant la partie nationale', () {
      expect(PhoneNumberFormat.toE164('816939060'), '+243816939060');
    });

    test('ne produit jamais un indicatif orphelin', () {
      expect(PhoneNumberFormat.toE164(''), '');
      expect(PhoneNumberFormat.toE164('   '), '');
    });
  });

  group('PhoneNumberFormat.normalize', () {
    test('ramène tous les formats hérités au même E.164', () {
      const expected = '+243816939060';
      for (final raw in <String>[
        '816939060',
        '0816939060',
        '+243816939060',
        '00243816939060',
        '+243 81 693 90 60',
        '(0)81-693-9060',
      ]) {
        expect(PhoneNumberFormat.normalize(raw), expected, reason: raw);
      }
    });
  });

  group('PhoneNumberFormat.isValid', () {
    test('exige le nombre exact de chiffres nationaux', () {
      expect(PhoneNumberFormat.isValid('+243816939060'), isTrue);
      expect(PhoneNumberFormat.isValid('0816939060'), isTrue);
      expect(PhoneNumberFormat.isValid('81693906'), isFalse);
      expect(PhoneNumberFormat.isValid('8169390600'), isFalse);
      expect(PhoneNumberFormat.isValid(''), isFalse);
    });
  });

  group('PhoneNumberFormat.canonicalE164', () {
    test('ramène les écritures du plan national au même numéro', () {
      const expected = '+243816939060';
      for (final raw in <String>[
        '816939060',
        '0816939060',
        '+243816939060',
        '00243816939060',
        '+243 81 693 90 60',
      ]) {
        expect(PhoneNumberFormat.canonicalE164(raw), expected, reason: raw);
      }
    });

    test('préserve un indicatif étranger au lieu de le supposer congolais', () {
      expect(PhoneNumberFormat.canonicalE164('+32470123456'), '+32470123456');
      expect(PhoneNumberFormat.canonicalE164('+242816939060'), '+242816939060');
    });
  });

  group('PhoneNumberFormat.sameNumber', () {
    test('rapproche deux écritures du même abonné', () {
      expect(
        PhoneNumberFormat.sameNumber('0816939060', '+243 81 693 90 60'),
        isTrue,
      );
    });

    test('ne confond PAS deux pays voisins aux mêmes derniers chiffres', () {
      // Kinshasa / Brazzaville : la troncature aux 9 derniers chiffres les
      // rendrait identiques, un élève serait rattaché au mauvais parent.
      expect(
        PhoneNumberFormat.sameNumber('+242816939060', '+243816939060'),
        isFalse,
      );
    });

    test('un numéro vide ne rapproche jamais', () {
      expect(PhoneNumberFormat.sameNumber('', ''), isFalse);
      expect(PhoneNumberFormat.sameNumber('', '+243816939060'), isFalse);
    });
  });

  group('PhoneNumberFormat.isForeign', () {
    test('reconnaît un numéro hors du plan de saisie', () {
      expect(PhoneNumberFormat.isForeign('+32470123456'), isTrue);
      expect(PhoneNumberFormat.isForeign('+242816939060'), isTrue);
    });

    test('ne signale ni le plan national ni une bribe locale', () {
      expect(PhoneNumberFormat.isForeign('+243816939060'), isFalse);
      expect(PhoneNumberFormat.isForeign('0816939060'), isFalse);
      expect(PhoneNumberFormat.isForeign('8169'), isFalse);
      expect(PhoneNumberFormat.isForeign(''), isFalse);
    });
  });
}
