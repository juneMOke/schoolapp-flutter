import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_score_palette.dart';

void main() {
  group('ResultatsScorePalette.toneFor (seuil 50)', () {
    test('null → none', () {
      expect(ResultatsScorePalette.toneFor(null, 50), ResultatsPctTone.none);
    });

    test('< seuil → fail', () {
      expect(ResultatsScorePalette.toneFor(49.9, 50), ResultatsPctTone.fail);
      expect(ResultatsScorePalette.toneFor(0, 50), ResultatsPctTone.fail);
    });

    test('[seuil, seuil+20[ → neutral', () {
      expect(ResultatsScorePalette.toneFor(50, 50), ResultatsPctTone.neutral);
      expect(ResultatsScorePalette.toneFor(69.9, 50), ResultatsPctTone.neutral);
    });

    test('>= seuil+20 → good', () {
      expect(ResultatsScorePalette.toneFor(70, 50), ResultatsPctTone.good);
      expect(ResultatsScorePalette.toneFor(100, 50), ResultatsPctTone.good);
    });

    test('le seuil déplace les bornes', () {
      expect(ResultatsScorePalette.toneFor(55, 60), ResultatsPctTone.fail);
      expect(ResultatsScorePalette.toneFor(60, 60), ResultatsPctTone.neutral);
      expect(ResultatsScorePalette.toneFor(80, 60), ResultatsPctTone.good);
    });
  });

  group('ResultatsScorePalette.noteColor', () {
    test('ratio < seuil → error', () {
      expect(ResultatsScorePalette.noteColor(9, 20, 50), AppColors.error);
    });

    test('ratio >= seuil → texte primaire', () {
      expect(
        ResultatsScorePalette.noteColor(10, 20, 50),
        AppColors.textPrimary,
      );
    });

    test('max nul → neutre (pas de division par zéro)', () {
      expect(ResultatsScorePalette.noteColor(0, 0, 50), AppColors.textPrimary);
    });
  });
}
