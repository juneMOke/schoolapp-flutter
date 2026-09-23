import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_key_figures.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_key_figure_cards.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La première couverture chromatique du module Recouvrement : il n'en avait
/// aucune avant ce lot, donc rien n'aurait signalé une dérive de teinte.
///
/// Les figures passées sont volontairement `empty` : les cinq teintes ne
/// dépendent pas des chiffres, et un test qui fabriquerait des sacs d'argent
/// pour vérifier une couleur mesurerait deux choses à la fois.
void main() {
  const seuil = 4.5;

  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  String hex(Color c) =>
      '#${((c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  List<EteeloKpiCardData> cards() =>
      recouvrementKeyFigureCards(RecouvrementKeyFigures.empty, l10n);

  test('la bande compte cinq pavés pleins, aucun en carte claire', () {
    final band = cards();
    expect(band, hasLength(5));
    for (final card in band) {
      expect(
        card.isFilled,
        isTrue,
        reason: 'la carte « ${card.label} » est restée claire',
      );
    }
  });

  test('les cinq fonds sont ceux que la spec publie', () {
    // Le triptyque de la spec — attendu / perçu / reste — puis les deux
    // effectifs, dans l'ordre de lecture de l'écran.
    final band = cards();
    expect(hex(band[0].filledBackground as Color), '#184662'); // attendu
    expect(hex(band[1].filledBackground as Color), '#335D48'); // perçu
    expect(hex(band[2].filledBackground as Color), '#993630'); // reste
    expect(hex(band[3].filledBackground as Color), '#993630'); // rien payé
    expect(hex(band[4].filledBackground as Color), '#855D0F'); // partiel
  });

  test('le reste et « rien payé » partagent le rouge du manquant', () {
    // Ce n'est pas une collision à corriger : un montant qui manque et un
    // effectif qui n'a rien versé sont la même mauvaise nouvelle, dite deux
    // fois. Le test fixe l'intention pour qu'une divergence future soit un
    // choix, pas un accident.
    final band = cards();
    expect(band[2].filledBackground, band[3].filledBackground);
    expect(band[2].icon, isNot(band[3].icon));
    expect(band[2].label, isNot(band[3].label));
  });

  test('les trois encres tiennent sur chacun des cinq pavés', () {
    for (final card in cards()) {
      final fond = card.filledBackground as Color;
      for (final (role, ink) in [
        ('valeur', DashboardTones.inkValeur),
        ('libellé', DashboardTones.inkLibelle),
        ('sous-ligne', DashboardTones.inkSousLigne),
      ]) {
        expect(
          ratio(ink, fond),
          greaterThanOrEqualTo(seuil),
          reason: '$role de « ${card.label} » sur ${hex(fond)}',
        );
      }
    }
  });

  group('encre de seconde devise', () {
    test('seuls les trois montants en portent une', () {
      final band = cards();
      // Les trois montants peuvent afficher deux devises : la seconde ligne
      // est un second montant, et la nuance le dit.
      expect(band[0].filledSecondaryInk, AppColors.paveInkAttendu);
      expect(band[1].filledSecondaryInk, AppColors.paveInkPercu);
      expect(band[2].filledSecondaryInk, AppColors.paveInkReste);
      // Les deux effectifs n'ont qu'un chiffre — une nuance n'y signalerait
      // rien, et en déclarer une serait du bruit.
      expect(band[3].filledSecondaryInk, isNull);
      expect(band[4].filledSecondaryInk, isNull);
    });

    test('chaque nuance est lisible sur le pavé qui la porte', () {
      for (final card in cards().where((c) => c.filledSecondaryInk != null)) {
        expect(
          ratio(
            card.filledSecondaryInk as Color,
            card.filledBackground as Color,
          ),
          greaterThanOrEqualTo(seuil),
          reason: 'seconde devise de « ${card.label} »',
        );
      }
    });
  });

  test('aucun accent de la bande n\'a besoin du garde-fou', () {
    // Si cette assertion tombe, c'est qu'un accent a été éclairci : le pavé
    // correspondant est alors substitué en silence et ne vaut plus la valeur
    // publiée ci-dessus. Mieux vaut l'apprendre ici.
    for (final card in cards()) {
      expect(
        DashboardTones.paveAccentSur(card.accent),
        card.accent,
        reason: 'l\'accent de « ${card.label} » est devenu trop clair',
      );
    }
  });
}
