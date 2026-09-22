import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/finance_till_tones.dart';

/// La couverture chromatique du tableau de bord de la caisse.
///
/// Le module n'en avait aucune : deux assertions de couleur dans tout
/// `test/features/finance`, dont aucune ne portait sur une teinte de devise.
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

  group('fidélité aux valeurs publiées', () {
    test('les trois pavés sont ceux de la spec', () {
      expect(hex(FinanceTillTones.paveDeCaisse('USD')), '#184662');
      expect(hex(FinanceTillTones.paveDeCaisse('CDF')), '#335D48');
      expect(hex(FinanceTillTones.paveDesRecus), '#855D0F');
    });

    test('le bandeau et la zébrure du tableau des reçus', () {
      final tone = FinanceTillTones.tableDesRecus;
      expect(hex(tone.header), '#885E0D');
      expect(hex(tone.zebra), '#F5F1E8');
    });

    test('une devise inconnue ne prend pas une couleur inventée', () {
      // La doctrine de l'écran : le gris du texte, jamais une troisième teinte
      // qui se lirait comme une catégorie de plus.
      final inconnue = FinanceTillTones.paveDeCaisse('XAF');
      expect(inconnue, isNot(FinanceTillTones.paveDeCaisse('USD')));
      expect(inconnue, isNot(FinanceTillTones.paveDeCaisse('CDF')));
      expect(
        ratio(DashboardTones.inkValeur, inconnue),
        greaterThanOrEqualTo(seuilTexte),
        reason: 'le pavé d\'une devise inconnue doit rester lisible',
      );
    });
  });

  group('encres sur les trois pavés', () {
    final paves = <String, Color>{
      'caisse USD': FinanceTillTones.paveDeCaisse('USD'),
      'caisse CDF': FinanceTillTones.paveDeCaisse('CDF'),
      'reçus émis': FinanceTillTones.paveDesRecus,
    };

    test('valeur, libellé et sous-ligne tiennent partout', () {
      paves.forEach((nom, fond) {
        for (final (role, ink) in [
          ('valeur', DashboardTones.inkValeur),
          ('libellé', DashboardTones.inkLibelle),
          ('sous-ligne', DashboardTones.inkSousLigne),
        ]) {
          expect(
            ratio(ink, fond),
            greaterThanOrEqualTo(seuilTexte),
            reason: '$role sur « $nom » ${hex(fond)}',
          );
        }
      });
    });

    test('le glyphe or clair passe le seuil des objets graphiques', () {
      paves.forEach((nom, fond) {
        final voile = Color.alphaBlend(
          DashboardTones.inkValeur.withValues(
            alpha: FinanceTillTones.voileMedaillon,
          ),
          fond,
        );
        expect(
          ratio(AppColors.orSurPave, voile),
          greaterThanOrEqualTo(seuilGraphique),
          reason: 'glyphe du médaillon sur « $nom »',
        );
      });
    });

    test(
      'contre-épreuve : `orDoux` aurait échoué sur deux pavés sur trois',
      () {
        // C'est le défaut que la bascule en pavés a introduit et que ce lot
        // corrige. Si cette assertion passe au vert, c'est que les fonds ont
        // changé — et il faudra le constater, pas le supposer.
        for (final nom in ['caisse CDF', 'reçus émis']) {
          final voile = Color.alphaBlend(
            DashboardTones.inkValeur.withValues(
              alpha: FinanceTillTones.voileMedaillon,
            ),
            paves[nom]!,
          );
          expect(
            ratio(AppColors.orDoux, voile),
            lessThan(seuilGraphique),
            reason: 'l\'or foncé devait échouer sur « $nom »',
          );
        }
      },
    );
  });

  group('la ligne de tendance', () {
    test('les deux nuances tiennent sur les deux pavés de caisse', () {
      for (final devise in ['USD', 'CDF']) {
        final fond = FinanceTillTones.paveDeCaisse(devise);
        for (final (sens, ink) in [
          ('hausse', FinanceTillTones.inkTendanceHausse),
          ('baisse', FinanceTillTones.inkTendanceBaisse),
        ]) {
          expect(
            ratio(ink, fond),
            greaterThanOrEqualTo(seuilTexte),
            reason: 'tendance en $sens sur la caisse $devise',
          );
        }
      }
    });

    test(
      'contre-épreuve : les teintes de la tuile blanche seraient illisibles',
      () {
        // 1,63 / 1,85 sur le pavé dollars, 1,21 / 1,38 sur le pavé francs. Ce
        // n'est pas une nuance de confort : la ligne disparaît.
        for (final devise in ['USD', 'CDF']) {
          final fond = FinanceTillTones.paveDeCaisse(devise);
          expect(ratio(AppColors.vertSavane, fond), lessThan(2.0));
          expect(ratio(AppColors.error, fond), lessThan(2.0));
        }
      },
    );
  });

  group('la pastille de source — écart E2', () {
    test('l\'encre boutique se lit, l\'accent seul ne se lisait pas', () {
      expect(
        ratio(FinanceTillTones.inkBoutique, AppColors.terreCuiteSoft),
        greaterThanOrEqualTo(seuilTexte),
      );
      // Contre-épreuve : la terre cuite pleine, qui peignait le libellé.
      expect(
        ratio(AppColors.terreCuite, AppColors.terreCuiteSoft),
        lessThan(seuilTexte),
        reason: 'si elle passe désormais, la scission accent/encre peut tomber',
      );
      // Elle reste en revanche valide pour l'ICÔNE, qui est un objet graphique.
      expect(
        ratio(AppColors.terreCuite, AppColors.terreCuiteSoft),
        greaterThanOrEqualTo(seuilGraphique),
      );
    });
  });
}
