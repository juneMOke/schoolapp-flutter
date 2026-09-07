import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_cycle_palette.dart';

void main() {
  group('cycleColorForCode', () {
    test('reconnaît les trois familles usuelles, dans les deux langues', () {
      for (final code in ['MATERNELLE', 'maternelle', 'PRESCOLAIRE']) {
        expect(
          cycleColorForCode(code),
          AppColors.enrollmentStatsCycleMaternelle,
          reason: code,
        );
      }
      for (final code in ['PRIMAIRE', 'PRIMARY', 'primaire']) {
        expect(
          cycleColorForCode(code),
          AppColors.enrollmentStatsCyclePrimaire,
          reason: code,
        );
      }
      for (final code in ['SECONDAIRE', 'SECONDARY', 'HUMANITES']) {
        expect(
          cycleColorForCode(code),
          AppColors.enrollmentStatsCycleSecondaire,
          reason: code,
        );
      }
    });

    test('traverse accents, séparateurs et préfixes d\'école', () {
      // Le code vient de `school_level_groups.code`, configuré par école : il
      // n'a ni casse ni ponctuation garanties.
      expect(
        cycleColorForCode('Cycle-Pré_scolaire'),
        AppColors.enrollmentStatsCycleMaternelle,
      );
      expect(
        cycleColorForCode('cycle primaire'),
        AppColors.enrollmentStatsCyclePrimaire,
      );
    });

    test('un code inconnu reçoit une couleur STABLE, pas un rang', () {
      // La propriété qui compte : le classement change d'une fenêtre à
      // l'autre, la couleur d'un cycle ne doit pas bouger avec lui.
      const codes = ['ZZ_ATELIER', 'QQ_INTERNAT', 'XX_ALTERNANCE'];
      final reference = {
        for (final code in codes) code: cycleColorForCode(code),
      };

      // Même liste permutée : chaque code retrouve exactement sa teinte.
      for (final permutation in [
        codes.reversed.toList(),
        [codes[1], codes[2], codes[0]],
        [codes[2], codes[0], codes[1]],
      ]) {
        for (final code in permutation) {
          expect(
            cycleColorForCode(code),
            reference[code],
            reason: '$code doit garder sa teinte quel que soit l\'ordre',
          );
        }
      }
    });

    test('un code inconnu reste dans la palette', () {
      final palette = [
        for (var i = 0; i < cyclePaletteLength; i++) cyclePaletteColor(i),
      ];
      expect(palette, contains(cycleColorForCode('ZZ_ATELIER')));
    });

    test('la palette de repli ne peint pas deux rangs de la même teinte', () {
      // ⚠️ Piège d'alias : `enrollmentStatsFirst` VAUT désormais `bleuArdoise`,
      // comme `enrollmentStatsAccent`. Les empiler peindrait deux cycles
      // identiques.
      final palette = [
        for (var i = 0; i < cyclePaletteLength; i++) cyclePaletteColor(i),
      ];
      expect(palette.toSet(), hasLength(cyclePaletteLength));
    });

    test('un code vide ne fait pas exploser le rendu', () {
      expect(() => cycleColorForCode(''), returnsNormally);
    });
  });
}
