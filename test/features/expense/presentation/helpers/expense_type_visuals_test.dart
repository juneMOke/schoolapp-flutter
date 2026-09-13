import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_type_visuals.dart';

void main() {
  test('les neuf icônes des types par défaut sont toutes connues', () {
    for (final name in [
      'power',
      'arrow-right-left',
      'book-marked',
      'settings',
      'phone',
      'shield-check',
      'sparkles',
      'shopping-bag',
      'layers',
    ]) {
      expect(
        ExpenseTypeVisuals.icon(name),
        isNot(ExpenseTypeVisuals.fallbackIcon),
        reason: name,
      );
    }
  });

  test('une icône inconnue retombe sur le repli', () {
    expect(ExpenseTypeVisuals.icon('rocket'), ExpenseTypeVisuals.fallbackIcon);
  });

  test('couleur : #RRGGBB opaque, illisible ⇒ null', () {
    expect(ExpenseTypeVisuals.color('#D9A24E'), const Color(0xFFD9A24E));
    expect(ExpenseTypeVisuals.color(' #d9a24e '), const Color(0xFFD9A24E));
    expect(ExpenseTypeVisuals.color('D9A24E'), isNull);
    expect(ExpenseTypeVisuals.color('#D9A24'), isNull);
    expect(ExpenseTypeVisuals.color(''), isNull);
  });
}
