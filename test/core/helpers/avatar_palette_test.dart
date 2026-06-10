import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/avatar_palette.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('AvatarPalette.colorFor', () {
    test('déterministe : même clé → même couleur', () {
      expect(
        AvatarPalette.colorFor('student-42'),
        AvatarPalette.colorFor('student-42'),
      );
    });

    test('clé vide → teinte stable et déterministe', () {
      expect(AvatarPalette.colorFor(''), AvatarPalette.colorFor(''));
    });

    test('contraste AA (≥4.5) sur blanc cassé ET sur papier, pour tout id', () {
      // Solid : initiales blanc cassé sur la teinte.
      // Outlined : teinte sur fond papier (surfaceAlt).
      for (var i = 0; i < 360; i++) {
        final tint = AvatarPalette.colorFor('eleve-$i');
        expect(
          _contrast(tint, AppColors.blancCasse),
          greaterThanOrEqualTo(4.5),
          reason: 'solid (blanc/teinte) id=$i',
        );
        expect(
          _contrast(tint, AppColors.surfaceAlt),
          greaterThanOrEqualTo(4.5),
          reason: 'outlined (teinte/papier) id=$i',
        );
      }
    });

    test(
      'variation maximale : très peu de collisions (≫ ancienne palette 8)',
      () {
        final seen = <int>{};
        for (var i = 0; i < 50; i++) {
          seen.add(AvatarPalette.colorFor('eleve-$i').toARGB32());
        }
        // Sur 50 élèves, on attend une quasi-unicité (bien au-delà des 8 teintes
        // de l'ancienne palette fixe).
        expect(seen.length, greaterThan(40));
      },
    );
  });
}
