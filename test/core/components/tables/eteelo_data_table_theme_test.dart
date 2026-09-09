import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';

/// **Une colonne de chiffres se parcourt du regard.**
void main() {
  bool isTabular(TextStyle style) =>
      (style.fontFeatures ?? const <FontFeature>[]).any(
        (feature) => feature.feature == 'tnum',
      );

  test('les trois variantes de cellule portent des chiffres tabulaires', () {
    // Sur les trois et non sur la seule colonne de montants : une date et un
    // numéro de pièce forment aussi des colonnes, et une table dont deux
    // colonnes s'alignent et trois autres non se lit plus mal que si aucune ne
    // s'alignait.
    expect(isTabular(EteeloDataTableTheme.cellRegularStyle), isTrue);
    expect(isTabular(EteeloDataTableTheme.cellStrongStyle), isTrue);
    expect(isTabular(EteeloDataTableTheme.cellMonoStyle), isTrue);
  });

  test('le reste du style de cellule est inchangé', () {
    // Le chiffre tabulaire ne devait rien emporter d'autre : mêmes tailles,
    // mêmes graisses, mêmes couleurs qu'avant.
    expect(EteeloDataTableTheme.cellRegularStyle.fontSize, 12);
    expect(EteeloDataTableTheme.cellStrongStyle.fontWeight, FontWeight.w600);
    expect(EteeloDataTableTheme.cellMonoStyle.letterSpacing, 0.3);
  });
}
