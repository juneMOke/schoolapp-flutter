import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';

void main() {
  group('toCents', () {
    final cases = <String, int?>{
      '385000': 38500000,
      '385 000': 38500000,
      '385 000': 38500000,
      '385.000': 38500000, // groupement : un centime n'a jamais 3 chiffres
      '1,200': 120000,
      '120,50': 12050,
      '120.5': 12050,
      '1.200,50': 120050,
      '1,200.50': 120050,
      '120,': 12000,
      ',5': 50,
      '0': null,
      '0,00': null,
      '': null,
      '  ': null,
      'abc': null,
      '12a': null,
      '-5': null,
      '1,2345': null,
    };
    cases.forEach((raw, expected) {
      test('« $raw » → $expected', () {
        expect(AmountInput.toCents(raw), expected);
      });
    });
  });

  test('fromCents : sans groupement, virgule décimale seulement si utile', () {
    expect(AmountInput.fromCents(38500000), '385000');
    expect(AmountInput.fromCents(12050), '120,50');
    expect(AmountInput.fromCents(12005), '120,05');
  });

  test('aller-retour : ce qui est réécrit se relit à l’identique', () {
    for (final cents in [1, 99, 100, 12050, 38500000]) {
      expect(AmountInput.toCents(AmountInput.fromCents(cents)), cents);
    }
  });

  test('toCentsOrZero : 0 est un montant, l illisible reste null', () {
    expect(AmountInput.toCentsOrZero('0'), 0);
    expect(AmountInput.toCentsOrZero('0,00'), 0);
    expect(AmountInput.toCentsOrZero('3 450 000'), 345000000);
    expect(AmountInput.toCentsOrZero(''), isNull);
    expect(AmountInput.toCentsOrZero('-5'), isNull);
    // toCents garde sa règle : un décaissement est strictement positif.
    expect(AmountInput.toCents('0'), isNull);
  });
}
