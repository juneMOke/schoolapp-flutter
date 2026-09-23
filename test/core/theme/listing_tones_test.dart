import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';

/// Contrastes et fidélité de la grammaire des écrans de liste.
///
/// Ce fichier est la remontée dans `core` de ce que
/// `enrollment_listing_tones_test.dart` vérifiait pour le seul module
/// Inscriptions. Il garde donc les **mêmes valeurs publiées** — c'est la
/// preuve que la mise en commun n'a rien déplacé — et y ajoute ce que la
/// mutualisation crée de neuf : une fabrique d'habillage de table paramétrée
/// par le ton, qui doit reproduire **les deux** implémentations qui
/// préexistaient, la terre cuite des listes et l'ocre du tableau des reçus.
void main() {
  const seuilTexte = 4.5;

  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  String hex(Color c) =>
      '#${((c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  group('fidélité aux valeurs publiées', () {
    test('les surfaces que la spec chiffre se reproduisent', () {
      expect(hex(ListingTones.table.header), '#965330');
      expect(hex(ListingTones.barreFond), '#F8EFEA');
      expect(hex(ListingTones.table.zebra), '#F6F1EB');
      expect(hex(ListingTones.formulaireFond), '#EFF3F5');
      expect(hex(ListingTones.formulaireBord), '#B9C0BC');
    });

    test('le bord de la barre suit la FORMULE, pas la valeur publiée', () {
      // La spec annonce #DFC0AC ; sa propre formule
      // `mix(--border, terre-cuite 26 %)` donne #D8BDA7, et aucune autre base
      // plausible ne redonne la valeur publiée. C'est la formule qui fait foi :
      // c'est elle qui se réutilise. Un bord décoratif n'ayant pas de seuil,
      // l'écart ne se voit pas — mais il ne doit pas se perdre non plus.
      expect(hex(ListingTones.barreBord), '#D8BDA7');
      expect(hex(ListingTones.barreBord), isNot('#DFC0AC'));
    });
  });

  group('la fabrique d\'habillage de table', () {
    test('la terre cuite redonne exactement l\'habillage des listes', () {
      expect(
        ListingTones.tableTone(ListingTones.zoneResultat),
        ListingTones.table,
      );
    });

    test('l\'ocre redonne exactement l\'habillage du tableau des reçus', () {
      // Le vrai enjeu de la mise en commun : la caisse composait ses cinq
      // couleurs à la main, avec les mêmes formules et un autre ton. Si la
      // fabrique ne la reproduit pas, elle n'est pas générale — elle est
      // seulement celle des listes portant un autre nom.
      final recus = ListingTones.tableTone(AppColors.insOcre);
      expect(hex(recus.header), '#885E0D');
      expect(hex(recus.zebra), '#F5F1E8');
    });

    test('ses deux encres tiennent le seuil sur CHAQUE bandeau produit', () {
      // La vérification porte sur l'objet réellement passé au composant, et
      // sur les deux tons qui existent en production — pas sur le seul ton par
      // défaut. Une fabrique paramétrée qui n'est vérifiée que sur son
      // argument habituel ne garantit rien de son paramètre.
      for (final tone in const [ListingTones.zoneResultat, AppColors.insOcre]) {
        final habillage = ListingTones.tableTone(tone);
        expect(
          ratio(habillage.headerInk, habillage.header),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'encre d\'en-tête sur ${hex(habillage.header)}',
        );
        expect(
          ratio(habillage.headerInkSorted, habillage.header),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'encre de colonne triée sur ${hex(habillage.header)}',
        );
      }
    });
  });

  group('encres sur les surfaces claires', () {
    test('l\'eyebrow terre cuite tient sur le fond de barre', () {
      expect(
        ratio(ListingTones.inkResultat, ListingTones.barreFond),
        greaterThanOrEqualTo(seuilTexte),
      );
    });

    test('contre-épreuve : la terre cuite claire ne tiendrait pas', () {
      // #B85C2C sur le voile de la pastille « niveau visé » : 4,04:1. C'est
      // tout l'objet du token assombri — si ce couple passe un jour, l'écart
      // n'a plus lieu d'être.
      expect(
        ratio(AppColors.terreCuite, const Color(0xFFFBEFE8)),
        lessThan(seuilTexte),
      );
    });

    test('TOUTES les encres qu\'une barre teintée porte tiennent', () {
      // La barre est teintée, son texte ne l'est pas : une surface colorée ne
      // colore pas ce qu'elle porte.
      //
      // On boucle sur les deux encres réellement posées sur une barre en
      // production — `textSecondary` pour le compte d'Inscriptions,
      // `textPrimary` pour le résumé de Classes — plutôt que de n'en vérifier
      // qu'une. Une surface vérifiée par une seule de ses encres est le défaut
      // qui revient le plus souvent dans ce chantier.
      for (final encre in const [
        AppColors.textPrimary,
        AppColors.textSecondary,
      ]) {
        expect(
          ratio(encre, ListingTones.barreFond),
          greaterThanOrEqualTo(seuilTexte),
        );
      }
    });

    test('les champs restent blancs sur le corps bleuté du formulaire', () {
      // C'est le contraste de SURFACE qui dit « ici, on saisit ». On vérifie
      // qu'il existe, sans quoi la règle est décorative.
      expect(
        ratio(AppColors.surfaceRaised, ListingTones.formulaireFond),
        greaterThan(1.02),
      );
    });
  });

  group('la zébrure ne porte aucune information', () {
    test('son écart est infime, et c\'est voulu', () {
      // Si ce ratio montait, la liste deviendrait bicolore — ce que le §12
      // interdit explicitement. Le test borne donc par le HAUT, et sur les
      // deux tons en production.
      for (final tone in const [ListingTones.zoneResultat, AppColors.insOcre]) {
        expect(
          ratio(ListingTones.tableTone(tone).zebra, AppColors.surface),
          lessThan(1.2),
          reason: 'une zébrure guide, elle ne dit rien',
        );
      }
    });
  });
}
