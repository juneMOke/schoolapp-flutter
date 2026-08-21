import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/formatters/text_capitalization_formatters.dart';

TextEditingValue _type(TextInputFormatter formatter, String text) {
  return formatter.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
}

void main() {
  group('WordCapitalizationInputFormatter', () {
    const formatter = WordCapitalizationInputFormatter();

    test('capitalise chaque mot', () {
      expect(_type(formatter, 'daniel kabongo').text, 'Daniel Kabongo');
    });

    test('le trait d\'union et l\'apostrophe ouvrent un mot', () {
      expect(_type(formatter, 'jean-pierre').text, 'Jean-Pierre');
      expect(_type(formatter, "n'djamena").text, "N'Djamena");
    });

    test('ne rabaisse jamais une capitale déjà saisie', () {
      expect(_type(formatter, 'KABONGO mwaMBA').text, 'KABONGO MwaMBA');
    });

    test('un chiffre ou un signe en tête ne fait pas perdre la majuscule', () {
      expect(_type(formatter, '2 rue kabila').text, '2 Rue Kabila');
    });

    test('texte vide : valeur rendue telle quelle', () {
      expect(_type(formatter, '').text, isEmpty);
    });

    test('la sélection reste dans les bornes du texte réécrit', () {
      final result = _type(formatter, 'daniel');
      expect(
        result.selection.baseOffset,
        lessThanOrEqualTo(result.text.length),
      );
      expect(
        result.selection.extentOffset,
        lessThanOrEqualTo(result.text.length),
      );
    });
  });

  group('SentenceCapitalizationInputFormatter', () {
    const formatter = SentenceCapitalizationInputFormatter();

    test('ne capitalise que la première lettre du champ', () {
      expect(
        _type(formatter, 'absence non justifiée signalée par le tuteur').text,
        'Absence non justifiée signalée par le tuteur',
      );
    });

    test('la première LETTRE, pas le premier caractère', () {
      expect(_type(formatter, '  motif tardif').text, '  Motif tardif');
      expect(_type(formatter, '3 retards ce mois').text, '3 Retards ce mois');
    });

    test('rien à faire quand la première lettre est déjà capitale', () {
      const already = 'Motif déjà écrit';
      expect(_type(formatter, already).text, already);
    });

    test('texte sans aucune lettre : valeur rendue telle quelle', () {
      expect(_type(formatter, '123 !').text, '123 !');
    });
  });
}
