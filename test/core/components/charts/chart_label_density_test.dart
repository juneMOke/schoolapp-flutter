import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/chart_label_density.dart';

/// Douze mois sous 300 dp se chevauchaient ; une étiquette sur deux se lit.
void main() {
  test('assez de place : toutes les étiquettes', () {
    expect(chartLabelStep(count: 6, width: 900, minSpacing: 44), 1);
  });

  test('téléphone, douze mois : une sur deux', () {
    expect(chartLabelStep(count: 12, width: 300, minSpacing: 44), 2);
  });

  test('très étroit : on espace d\'autant', () {
    expect(chartLabelStep(count: 12, width: 130, minSpacing: 44), 6);
  });

  test('cas limites : un point, aucune largeur', () {
    expect(chartLabelStep(count: 1, width: 10, minSpacing: 44), 1);
    expect(chartLabelStep(count: 8, width: 0, minSpacing: 44), 1);
    expect(chartLabelStep(count: 8, width: 20, minSpacing: 44), 8);
  });
}
