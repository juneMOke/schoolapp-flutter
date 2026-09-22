import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// Le test de non-régression que la spec Tableaux de bord réclame à son §11 :
/// « un test itère `paveAccents × pave()` et échoue si l'encre principale
/// descend sous 4,5:1 — c'est exactement ce test qui aurait attrapé E1 et E5. »
///
/// Il est écrit ici, et pas dans un module, parce que la grammaire est
/// partagée : quatre tableaux de bord la consomment, et un test par module
/// laisserait passer le cinquième.
void main() {
  const seuil = 4.5;

  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  String hex(Color c) =>
      '#${((c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// Les cinq sens qui peignent un pavé. Le sixième — `prestige` — n'en peint
  /// jamais : c'est précisément ce que le garde-fou fait respecter.
  const accentsDePave = <String, Color>{
    'attendu': DashboardSense.attendu,
    'encaisse': DashboardSense.encaisse,
    'manquant': DashboardSense.manquant,
    'attente': DashboardSense.attente,
    'marque': DashboardSense.marque,
  };

  group('fidélité aux valeurs publiées', () {
    test('les cinq fonds de pavé se reproduisent', () {
      expect(hex(DashboardTones.pave(DashboardSense.attendu)), '#184662');
      expect(hex(DashboardTones.pave(DashboardSense.encaisse)), '#335D48');
      expect(hex(DashboardTones.pave(DashboardSense.manquant)), '#993630');
      expect(hex(DashboardTones.pave(DashboardSense.marque)), '#935231');
      expect(hex(DashboardTones.pave(DashboardSense.attente)), '#855D0F');
    });

    test('le bandeau et la zébrure du tableau des reçus se reproduisent', () {
      expect(hex(DashboardTones.entete(DashboardSense.attente)), '#885E0D');
      expect(hex(DashboardTones.zebrure(DashboardSense.attente)), '#F5F1E8');
    });
  });

  group('encres de pavé — les trois, sur les cinq accents', () {
    test('aucune ne descend sous le seuil', () {
      accentsDePave.forEach((nom, accent) {
        final fond = DashboardTones.pave(accent);
        for (final (role, ink) in [
          ('valeur', DashboardTones.inkValeur),
          ('libellé', DashboardTones.inkLibelle),
          ('sous-ligne', DashboardTones.inkSousLigne),
        ]) {
          expect(
            ratio(ink, fond),
            greaterThanOrEqualTo(seuil),
            reason: '$role du pavé « $nom » sur $fond',
          );
        }
      });
    });

    test('les sous-lignes teintées du bi-devise tiennent aussi', () {
      // Le seul endroit du produit où une sous-ligne porte une nuance.
      for (final (nom, ink, accent) in [
        ('attendu', AppColors.paveInkAttendu, DashboardSense.attendu),
        ('perçu', AppColors.paveInkPercu, DashboardSense.encaisse),
        ('reste', AppColors.paveInkReste, DashboardSense.manquant),
      ]) {
        expect(
          ratio(ink, DashboardTones.pave(accent)),
          greaterThanOrEqualTo(seuil),
          reason: 'seconde devise du pavé « $nom »',
        );
      }
    });
  });

  group('garde-fou — un accent trop clair ne peint jamais un pavé', () {
    test('les substituts de FOND rendent un pavé lisible', () {
      for (final (nom, avant) in [
        ('or', AppColors.orDoux),
        ('ambre', AppColors.warning),
        ('gris', AppColors.textMuted),
      ]) {
        final fond = DashboardTones.pave(DashboardTones.paveAccentSur(avant));
        expect(
          ratio(DashboardTones.inkValeur, fond),
          greaterThanOrEqualTo(seuil),
          reason: 'valeur sur le pavé substitué de $nom',
        );
        expect(
          ratio(DashboardTones.inkSousLigne, fond),
          greaterThanOrEqualTo(seuil),
          reason: 'sous-ligne sur le pavé substitué de $nom',
        );
      }
    });

    test('un accent de pavé déjà sombre traverse inchangé', () {
      for (final accent in accentsDePave.values) {
        expect(DashboardTones.paveAccentSur(accent), accent);
      }
    });

    test('les substituts d\'ENCRE sont lisibles sur une carte blanche', () {
      // Le cas réel des bandes de KPI de Dépenses, Disciplines et
      // Recouvrement : la valeur du chiffre s'écrit dans l'accent.
      for (final (nom, avant) in [
        ('or', AppColors.orDoux),
        ('ambre', AppColors.warning),
        ('ocre', AppColors.insOcre),
        ('gris', AppColors.textMuted),
      ]) {
        expect(
          ratio(avant, AppColors.surfaceRaised),
          lessThan(seuil),
          reason: 'contre-épreuve : $nom devait échouer en texte',
        );
        expect(
          ratio(DashboardTones.encreLisible(avant), AppColors.surfaceRaised),
          greaterThanOrEqualTo(seuil),
          reason: 'encre substituée de $nom',
        );
        expect(DashboardTones.estCouleurDeSurface(avant), isTrue);
      }
    });

    test('les deux tables ne se confondent pas — le cas de l\'ocre', () {
      // L'ocre fonde un pavé très correctement mais ne se lit pas sur du
      // blanc. Une table unique aurait laissé passer l'un ou cassé l'autre.
      final fondOcre = DashboardTones.pave(DashboardSense.attente);
      expect(
        ratio(DashboardTones.inkValeur, fondOcre),
        greaterThanOrEqualTo(seuil),
        reason: 'en FOND, l\'ocre est valide et ne doit pas être substitué',
      );
      expect(
        DashboardTones.paveAccentSur(DashboardSense.attente),
        DashboardSense.attente,
      );
      expect(
        ratio(DashboardSense.attente, AppColors.surfaceRaised),
        lessThan(seuil),
        reason: 'en ENCRE, le même ocre échoue',
      );
      expect(
        DashboardTones.encreLisible(DashboardSense.attente),
        AppColors.ambreInk,
      );
    });

    test('contre-épreuve E1 : sans substitution, les deux échoueraient', () {
      // C'est le défaut que le garde-fou existe pour empêcher, et il ne se
      // déclenche que chez les écoles dont la dépense dominante est celle-là —
      // donc jamais en relecture.
      expect(
        ratio(DashboardTones.inkValeur, DashboardTones.pave(AppColors.orDoux)),
        lessThan(seuil),
        reason: 'si l\'or passe désormais, la substitution peut tomber',
      );
      expect(
        ratio(
          DashboardTones.inkSousLigne,
          DashboardTones.pave(AppColors.textMuted),
        ),
        lessThan(seuil),
        reason:
            'la VALEUR du pavé gris tient à 4,7 — c\'est sa SOUS-LIGNE '
            'qui tombe, et c\'est elle que la spec n\'avait pas mesurée',
      );
    });
  });

  group('force de teinte — densité perçue constante', () {
    test('le texte secondaire tient sur toutes les cartes de section', () {
      for (final tone in [
        AppColors.bleuProfond,
        AppColors.bleuArdoise,
        AppColors.vertSavane,
        AppColors.terreCuite,
        AppColors.error,
        AppColors.insOcre,
        AppColors.enrollmentStatsFemale,
      ]) {
        final (fond, _) = DashboardTones.section(tone);
        expect(
          ratio(AppColors.textSecondary, fond),
          greaterThanOrEqualTo(seuil),
          reason: 'section teintée ${hex(tone)}',
        );
      }
    });

    test('le barème suit la chaleur du ton, pas une valeur unique', () {
      expect(DashboardTones.forceDe(AppColors.bleuProfond), 8);
      expect(DashboardTones.forceDe(AppColors.terreCuite), 9);
      expect(DashboardTones.forceDe(AppColors.error), 9);
      expect(DashboardTones.forceDe(AppColors.bleuArdoise), 10);
      expect(DashboardTones.forceDe(AppColors.insOcre), 10);
    });
  });

  group('contre-épreuve E5 — l\'ambre en valeur de KPI', () {
    test('#D68910 ne tient pas sur une carte blanche', () {
      // Disciplines écrit ses taux en 700/30 dans la couleur de l'accent. Pour
      // l'ambre, cela fait 2,8:1 — sous le seuil même pour du texte large.
      expect(
        ratio(AppColors.warning, AppColors.surfaceRaised),
        lessThan(seuil),
      );
      // Et son glyphe sur voile est plus bas encore, ce que la spec ne relève
      // pas : elle ne mesure que la valeur.
      expect(
        ratio(AppColors.warning, AppColors.presenceStateJustifiedSoft),
        lessThan(3.0),
      );
      // L'ambre lisible, lui, passe largement.
      expect(
        ratio(AppColors.ambreInk, AppColors.surfaceRaised),
        greaterThanOrEqualTo(seuil),
      );
    });
  });
}
