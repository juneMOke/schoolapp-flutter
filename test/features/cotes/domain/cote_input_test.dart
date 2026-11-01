import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';

void main() {
  group('lecture d\'une frappe', () {
    test('vide', () {
      expect(parseCoteInput('  ', 20), isA<CoteInputEmpty>());
    });

    test('virgule et point', () {
      expect((parseCoteInput('12,5', 20) as CoteInputValue).value, 12.5);
      expect((parseCoteInput('12.5', 20) as CoteInputValue).value, 12.5);
    });

    test('en cours de frappe', () {
      expect((parseCoteInput('12,', 20) as CoteInputValue).value, 12);
      expect((parseCoteInput(',5', 20) as CoteInputValue).value, .5);
    });

    test('aux bornes', () {
      expect(parseCoteInput('0', 20), isA<CoteInputValue>());
      expect(parseCoteInput('20', 20), isA<CoteInputValue>());
      expect(parseCoteInput('20,01', 20), isA<CoteInputInvalid>());
      expect(parseCoteInput('139,5', 140), isA<CoteInputValue>());
    });

    test('plus de deux décimales ou illisible', () {
      expect(parseCoteInput('12,255', 20), isA<CoteInputInvalid>());
      expect(parseCoteInput(',', 20), isA<CoteInputInvalid>());
      expect(parseCoteInput('1,2,3', 20), isA<CoteInputInvalid>());
      expect(parseCoteInput('-1', 20), isA<CoteInputInvalid>());
    });
  });

  group('affichage', () {
    test('sans zéro inutile', () {
      expect(formatCote(14), '14');
      expect(formatCote(14.5), '14,5');
      expect(formatCote(14.25), '14,25');
      expect(formatCote(14.05), '14,05');
      expect(formatCote(0), '0');
    });

    test('centièmes exacts', () {
      expect(toCentis(14.55), 1455);
      expect(formatCentis(6150), '61,5');
    });
  });
}
