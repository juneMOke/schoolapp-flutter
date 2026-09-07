import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// Les teintes du tableau de bord des inscriptions, verrouillées sur les
/// valeurs de la spec « Inscriptions ▸ Tableau de bord ».
///
/// Ces tokens portent un **sens** (première inscription, réinscription, filles,
/// garçons, cycle) et non un goût : les intervertir a déjà produit un écran
/// où la bande KPI et la barre « Par type » se contredisaient. Ce test est là
/// pour que la prochaine retouche de palette le dise tout haut.
void main() {
  group('palette des inscriptions — conformité à la spec', () {
    test('type d\'inscription : Première bleu ardoise, Ré vert savane', () {
      // Spec l.333-334 (cartes KPI) et l.429-435 (barre « Par type »).
      expect(AppColors.enrollmentStatsFirst, const Color(0xFF1B4D6B));
      expect(AppColors.enrollmentStatsRe, const Color(0xFF3D6B4A));
      // Les pastilles diluées des cartes KPI suivent le même appariement.
      expect(AppColors.enrollmentStatsFirstSoft, const Color(0xFFEBF2F7));
      expect(AppColors.enrollmentStatsReSoft, const Color(0xFFEDF5EF));
    });

    test('filles et garçons', () {
      // Spec l.407-413.
      expect(AppColors.enrollmentStatsFemale, const Color(0xFF9D174D));
      expect(AppColors.enrollmentStatsMale, const Color(0xFF1B4D6B));
    });

    test('barre normale du rythme — un remplissage, pas une surface', () {
      // Spec l.377. `enrollmentStatsPreSoft` (#E8F3F7) est un fond de carte :
      // employé comme barre, il noyait le relief du bucket courant.
      expect(AppColors.enrollmentStatsPaceBar, const Color(0xFFA9C4D6));
      expect(
        AppColors.enrollmentStatsPaceBar,
        isNot(AppColors.enrollmentStatsPreSoft),
      );
    });

    test('teintes de cycle', () {
      // Spec l.481.
      expect(AppColors.enrollmentStatsCycleMaternelle, const Color(0xFF2E6E8E));
      expect(AppColors.enrollmentStatsCyclePrimaire, const Color(0xFF1B4D6B));
      expect(AppColors.enrollmentStatsCycleSecondaire, const Color(0xFFB85C2C));
    });
  });
}
