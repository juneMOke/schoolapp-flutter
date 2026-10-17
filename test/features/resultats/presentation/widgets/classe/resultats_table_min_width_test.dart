import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/classe/resultats_table_row.dart';

void main() {
  test('la largeur minimale croît d’une colonne par sous-période', () {
    final step = resultatsTableMinWidth(4) - resultatsTableMinWidth(3);
    expect(step, kResultatsFlexUnitMinWidth * kResultatsPeriodFlex);
  });

  test('sans sous-période : rang, élève, moyenne, chevron et marges', () {
    expect(
      resultatsTableMinWidth(0),
      kResultatsRankColWidth +
          kResultatsChevronColWidth +
          AppSpacing.md * 2 +
          kResultatsFlexUnitMinWidth *
              (kResultatsEleveFlex + kResultatsMoyenneFlex),
    );
  });
}
