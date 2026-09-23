import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// La première couverture chromatique du **tableau de bord Disciplines**.
///
/// Le module avait bien une assertion de couleur, mais elle portait sur la
/// fiche élève — un autre écran. Cet écran-ci n'en avait aucune.
///
/// Ce que ce lot corrige : la triade présence / justifiée / non justifiée
/// peint à la fois des **surfaces** (segments de barre, pastilles, mini-barres)
/// et du **texte** (valeur de légende, cellules de taux). Les surfaces gardent
/// la teinte pleine — c'est leur rôle. Le texte passe par le garde-fou, parce
/// que l'ambre `#D68910` n'y tient que 2,82:1.
void main() {
  const seuilTexte = 4.5;

  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Le fond d'une ligne alternée, **recomposé comme le widget le compose** :
  /// `surfaceAlt` à 45 % par-dessus la carte. Écrire `#F9F7F2` en dur cesserait
  /// d'être vrai le jour où l'alpha change, sans que rien ne le signale.
  final zebrure = Color.alphaBlend(
    AppColors.surfaceAlt.withValues(alpha: 0.45),
    AppColors.surfaceRaised,
  );

  final fonds = <String, Color>{
    'carte': AppColors.surfaceRaised,
    'ligne alternée': zebrure,
  };

  group('la triade en TEXTE passe par le garde-fou', () {
    test('l\'ambre est substitué, le vert et le rouge traversent', () {
      expect(
        DashboardTones.encreLisibleSur(
          AppColors.warning,
          AppColors.surfaceRaised,
        ),
        AppColors.ambreInk,
      );
      for (final deja in [AppColors.vertSavane, AppColors.error]) {
        expect(
          DashboardTones.encreLisibleSur(deja, AppColors.surfaceRaised),
          deja,
          reason: 'une couleur déjà conforme ne doit pas être assombrie',
        );
      }
    });

    test('les trois encres tiennent sur les deux fonds de ligne', () {
      fonds.forEach((nom, fond) {
        for (final (role, brut) in [
          ('présence', AppColors.vertSavane),
          ('justifiée', AppColors.warning),
          ('non justifiée', AppColors.error),
        ]) {
          final encre = DashboardTones.encreLisibleSur(
            brut,
            AppColors.surfaceRaised,
          );
          expect(
            ratio(encre, fond),
            greaterThanOrEqualTo(seuilTexte),
            reason: '$role sur « $nom »',
          );
        }
      });
    });

    test('contre-épreuve : l\'ambre brut échouait sur les deux', () {
      // 2,82 sur la carte, 2,63 sur la ligne alternée. Si cette assertion
      // passe au vert, c'est que `warning` a changé — et la substitution
      // pourra être revue, mais il faudra l'avoir constaté.
      fonds.forEach((nom, fond) {
        expect(
          ratio(AppColors.warning, fond),
          lessThan(seuilTexte),
          reason: 'l\'ambre brut devait échouer sur « $nom »',
        );
      });
    });
  });

  test('les SURFACES gardent la teinte pleine — elles ne sont pas du texte', () {
    // Segments de barre, pastilles de légende, mini-barres du tableau : le
    // garde-fou ne doit pas s'y appliquer. Un seuil de texte imposé à un aplat
    // aurait délavé le code couleur de la triade sans rien gagner.
    expect(AppColors.warning, isNot(AppColors.ambreInk));
    expect(
      ratio(AppColors.warning, AppColors.surfaceRaised),
      lessThan(seuilTexte),
      reason: 'et c\'est admis : un segment de barre n\'est pas lu, il est vu',
    );
  });
}
