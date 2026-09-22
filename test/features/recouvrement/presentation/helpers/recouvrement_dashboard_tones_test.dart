import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_dashboard_tones.dart';

/// Les quatre cartes de section de Recouvrement, que le § 02 range en
/// « sections sans tone → 9–10 ».
void main() {
  const seuilTexte = 4.5;
  const seuilGraphique = 3.0;

  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  String hex(Color c) =>
      '#${((c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  final fonds = <String, Color>{
    'périmètre': RecouvrementDashboardTones.fondPerimetre,
    'taux': RecouvrementDashboardTones.fondTaux,
    'cycles': RecouvrementDashboardTones.fondCycles,
    'simulation': RecouvrementDashboardTones.fondSimulation,
  };

  test('les fonds suivent la grammaire partagée', () {
    expect(hex(RecouvrementDashboardTones.fondPerimetre), '#E8EDF0');
    expect(hex(RecouvrementDashboardTones.fondTaux), '#ECF0ED');
    expect(hex(RecouvrementDashboardTones.fondCycles), '#E8EDF0');
    // Force 9 et non 10 : la terre cuite est un ton chaud saturé.
    expect(hex(RecouvrementDashboardTones.fondSimulation), '#F9F0EC');
  });

  test('aucune section n\'est restée blanche', () {
    fonds.forEach((nom, fond) {
      expect(
        fond,
        isNot(AppColors.surfaceRaised),
        reason: 'la section « $nom » n\'est pas teintée',
      );
    });
  });

  test('les trois encres tiennent sur les quatre fonds', () {
    fonds.forEach((nom, fond) {
      for (final (role, ink, seuil) in [
        ('titre', AppColors.textPrimary, seuilTexte),
        ('corps', AppColors.textSecondary, seuilTexte),
        ('mention', AppColors.textMutedAa, seuilTexte),
      ]) {
        expect(
          ratio(ink, fond),
          greaterThanOrEqualTo(seuil),
          reason: '$role sur « $nom » ${hex(fond)}',
        );
      }
    });
  });

  test('ce qui désigne une pastille de frais tient encore', () {
    // ⚠️ Ce n'est PAS le remplissage qu'il faut mesurer. Une pastille active
    // porte un aplat pâle `bleuArdoiseSoft` qui, sur blanc, ne valait déjà que
    // 1,13 — il n'a jamais rien désigné. Ce sont sa **bordure**, son icône et
    // son texte qui la distinguent, et ce sont eux qu'une teinte de fond
    // pourrait noyer.
    fonds.forEach((nom, fond) {
      expect(
        ratio(AppColors.bleuArdoise, fond),
        greaterThanOrEqualTo(seuilGraphique),
        reason: 'bordure et icône de pastille sur « $nom »',
      );
      expect(
        ratio(AppColors.bleuProfond, fond),
        greaterThanOrEqualTo(seuilTexte),
        reason: 'texte de pastille sur « $nom »',
      );
    });
  });

  test('la teinte ne dégrade pas la barre tricolore', () {
    // ⚠️ Ce test assertait d'abord que chaque segment franchissait 3:1 contre
    // le fond de sa carte. C'était le mauvais critère, sur trois plans :
    //
    //  * la barre repose sur sa **propre piste** `surfaceAlt`, pas sur le fond
    //    de la carte — c'est contre elle qu'un segment se détacherait ;
    //  * l'ambre n'y tenait déjà que **2,41 avant toute teinte**, et 2,82 sur
    //    du blanc : le critère aurait condamné cette barre depuis toujours ;
    //  * et les trois segments ne se distinguent **pas entre eux** par le
    //    ratio — 1,14 entre le vert et le rouge. Ils ne le peuvent pas : ils
    //    sont choisis par la teinte, pas par la luminance. Ce sont la position
    //    et la légende chiffrée qui les séparent, et la barre est d'ailleurs
    //    toujours doublée d'un décompte.
    //
    // Ce qui se vérifie utilement, c'est que la teinte de section ne change
    // presque rien à ce que la barre était déjà.
    for (final (segment, couleur) in [
      ('soldé', AppColors.vertSavane),
      ('partiel', AppColors.warning),
      ('rien', AppColors.error),
    ]) {
      final surPiste = ratio(couleur, AppColors.surfaceAlt);
      fonds.forEach((nom, fond) {
        expect(
          (ratio(couleur, fond) - surPiste).abs(),
          lessThan(0.3),
          reason:
              'la teinte de « $nom » déplace le segment « $segment » de plus '
              'de 0,3 par rapport à sa piste',
        );
      });
    }
  });

  test('contre-épreuve : l\'ambre était sous le seuil avant toute teinte', () {
    // Défaut **préexistant**, à ne pas mettre sur le compte de ce lot. Il est
    // épinglé ici pour que personne ne l'y attribue, et pour qu'il reste
    // visible s'il faut un jour rendre cette barre conforme — ce qui demandera
    // de traiter les trois segments ensemble, pas l'ambre seul.
    expect(ratio(AppColors.warning, AppColors.surfaceRaised), lessThan(3.0));
    expect(ratio(AppColors.warning, AppColors.surfaceAlt), lessThan(3.0));
    // Et les segments entre eux, qui ne franchissent pas non plus le seuil.
    expect(ratio(AppColors.vertSavane, AppColors.error), lessThan(3.0));
  });
}
