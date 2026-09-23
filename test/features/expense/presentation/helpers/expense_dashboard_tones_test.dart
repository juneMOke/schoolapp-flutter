import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_dashboard_tones.dart';

/// La première couverture chromatique du module Dépenses — et la seule du
/// produit qui porte sur une teinte **venue du serveur**.
void main() {
  const seuil = 4.5;

  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  String hex(Color c) =>
      '#${((c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  group('les trois pavés fixes', () {
    test('reproduisent les valeurs publiées', () {
      expect(hex(ExpenseDashboardTones.paveTotal), '#935231');
      expect(hex(ExpenseDashboardTones.paveRestant), '#855D0F');
      expect(hex(ExpenseDashboardTones.paveEnregistrees), '#184662');
    });

    test('les trois encres y tiennent', () {
      for (final fond in [
        ExpenseDashboardTones.paveTotal,
        ExpenseDashboardTones.paveRestant,
        ExpenseDashboardTones.paveEnregistrees,
      ]) {
        for (final ink in [
          DashboardTones.inkValeur,
          DashboardTones.inkLibelle,
          DashboardTones.inkSousLigne,
        ]) {
          expect(
            ratio(ink, fond),
            greaterThanOrEqualTo(seuil),
            reason: 'encre sur ${hex(fond)}',
          );
        }
      }
    });
  });

  group('le poste principal — la teinte serveur', () {
    /// Ce qu'une école peut mettre dans `ref_expense_types.color`. Les deux
    /// premières sont les valeurs du seed ; les quatre suivantes n'existent
    /// dans aucune table et ne sont donc rattrapées que par le calcul.
    const teintesServeur = <String, Color>{
      'or (seed Électricité)': Color(0xFFD9A24E),
      'ocre (seed)': Color(0xFFA66A00),
      'menthe': Color(0xFF7FD1AE),
      'jaune vif': Color(0xFFF2C94C),
      'rose': Color(0xFFF2A2C0),
      'cyan': Color(0xFF56CCF2),
    };

    test('quelle que soit la teinte, l\'encre crème reste lisible', () {
      teintesServeur.forEach((nom, brut) {
        final fond = ExpenseDashboardTones.pavePostePrincipal(brut);
        expect(
          ratio(DashboardTones.inkValeur, fond),
          greaterThanOrEqualTo(seuil),
          reason: 'valeur sur le pavé de « $nom » ${hex(fond)}',
        );
        expect(
          ratio(DashboardTones.inkSousLigne, fond),
          greaterThanOrEqualTo(seuil),
          reason: 'sous-ligne sur le pavé de « $nom »',
        );
      });
    });

    test('contre-épreuve : sans garde-fou, quatre sur six échoueraient', () {
      // C'est l'écart E1. Le défaut ne se déclenche que chez les écoles dont
      // la dépense dominante porte une de ces teintes — aucune relecture ne
      // l'aurait vu, et c'est pourquoi il est épinglé ici.
      var echecs = 0;
      teintesServeur.forEach((nom, brut) {
        if (ratio(DashboardTones.inkValeur, DashboardTones.pave(brut)) <
            seuil) {
          echecs++;
        }
      });
      expect(
        echecs,
        greaterThanOrEqualTo(4),
        reason: 'si plus rien n\'échoue brut, le garde-fou peut tomber',
      );
    });

    test('les teintes du seed passent par la table, pas par le calcul', () {
      // L'or est l'un des quatre substituts de marque : son pavé doit être
      // celui de l'attente, pas une valeur dérivée.
      expect(
        ExpenseDashboardTones.pavePostePrincipal(AppColors.orDoux),
        DashboardTones.pave(DashboardSense.attente),
      );
      // Et le gris muet — le cas « Divers » — passe par `textMutedAa`.
      expect(
        ExpenseDashboardTones.pavePostePrincipal(AppColors.textMuted),
        DashboardTones.pave(AppColors.textMutedAa),
      );
    });

    test('une teinte déjà sombre n\'est pas assombrie inutilement', () {
      for (final sombre in [AppColors.bleuArdoise, AppColors.error]) {
        expect(
          ExpenseDashboardTones.pavePostePrincipal(sombre),
          DashboardTones.pave(sombre),
        );
      }
    });
  });

  group('les cartes de section', () {
    const seuilGraphique = 3.0;

    final sections = <String, (Color accent, Color soft, Color fond)>{
      'marque — évolution et répartition': (
        ExpenseDashboardTones.accentMarque,
        ExpenseDashboardTones.accentSoftMarque,
        ExpenseDashboardTones.fondMarque,
      ),
      'neutre — postes coûteux': (
        ExpenseDashboardTones.accentNeutre,
        ExpenseDashboardTones.accentSoftNeutre,
        ExpenseDashboardTones.fondNeutre,
      ),
    };

    test('les deux fonds suivent la grammaire partagée', () {
      // Force 9 pour la terre cuite — ton chaud saturé — et 10 pour le bleu.
      expect(hex(ExpenseDashboardTones.fondMarque), '#F9F0EC');
      expect(hex(ExpenseDashboardTones.fondNeutre), '#E8EDF0');
    });

    test('aucune section n\'est restée blanche', () {
      sections.forEach((nom, s) {
        expect(s.$3, isNot(AppColors.surfaceRaised), reason: nom);
      });
    });

    test('les trois encres tiennent sur les deux fonds', () {
      sections.forEach((nom, s) {
        for (final (role, ink) in [
          ('titre', AppColors.textPrimary),
          ('corps', AppColors.textSecondary),
          ('sous-titre', AppColors.textMutedAa),
        ]) {
          expect(
            ratio(ink, s.$3),
            greaterThanOrEqualTo(seuil),
            reason: '$role sur « $nom » ${hex(s.$3)}',
          );
        }
      });
    });

    test('le médaillon suit son ton, et son glyphe reste lisible', () {
      // ⚠️ Ce qui se mesure ici, c'est le **glyphe** — le porteur. Pas le
      // remplissage du médaillon contre le fond de la carte : un aplat pâle
      // n'a jamais désigné quoi que ce soit, et le mesurer conduit à annoncer
      // des défauts qui n'existent pas.
      sections.forEach((nom, s) {
        expect(
          ratio(s.$1, s.$2),
          greaterThanOrEqualTo(seuilGraphique),
          reason: 'glyphe sur son voile — $nom',
        );
        expect(
          ratio(s.$1, s.$3),
          greaterThanOrEqualTo(seuilGraphique),
          reason: 'glyphe sur le fond de sa carte — $nom',
        );
      });
    });

    test('contre-épreuve : le gris muet ne tiendrait sur aucun des deux', () {
      // Ce qui rend la conversion vers `textMutedAa` nécessaire, et non
      // cosmétique. Il échouait déjà sur blanc à 3,69 : la teinte aggrave,
      // elle n'invente pas.
      sections.forEach((nom, s) {
        expect(ratio(AppColors.textMuted, s.$3), lessThan(seuil), reason: nom);
      });
    });
  });
}
