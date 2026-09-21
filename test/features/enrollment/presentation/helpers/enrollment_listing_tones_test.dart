import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_listing_tones.dart';

/// Contrastes et fidélité des teintes de liste (spec Première inscription).
///
/// Cette spec est la plus saine des trois : onze de ses treize ratios
/// vérifiables tombent au centième, et les deux qui divergent **sous-estiment**
/// — leurs verdicts tiennent donc tous. Ce test fige ce constat, ainsi que la
/// seule valeur publiée que sa propre formule ne reproduit pas.
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
    test('les quatre surfaces que la spec chiffre se reproduisent', () {
      expect(hex(EnrollmentListingTones.tableEntete), '#965330');
      expect(hex(EnrollmentListingTones.barreFond), '#F8EFEA');
      expect(hex(EnrollmentListingTones.tableZebrure), '#F6F1EB');
      expect(hex(EnrollmentListingTones.formulaireFond), '#EFF3F5');
      expect(hex(EnrollmentListingTones.formulaireBord), '#B9C0BC');
    });

    test('le bord de la barre suit la FORMULE, pas la valeur publiée', () {
      // La spec annonce #DFC0AC ; sa propre formule
      // `mix(--border, terre-cuite 26 %)` donne #D8BDA7, et aucune autre base
      // plausible ne redonne la valeur publiée. C'est la formule qui fait foi :
      // c'est elle qui se réutilise. Un bord décoratif n'ayant pas de seuil,
      // l'écart ne se voit pas — mais il ne doit pas se perdre non plus.
      expect(hex(EnrollmentListingTones.barreBord), '#D8BDA7');
      expect(hex(EnrollmentListingTones.barreBord), isNot('#DFC0AC'));
    });
  });

  group('l\'habillage passé au socle', () {
    test('la teinte de table compose les surfaces attendues', () {
      final tone = EnrollmentListingTones.table;
      expect(hex(tone.header), '#965330');
      expect(hex(tone.zebra), '#F6F1EB');
      expect(tone.headerInk, EnrollmentListingTones.inkEnteteTable);
      expect(tone.headerInkSorted, EnrollmentListingTones.inkEnteteTri);
    });

    test('ses deux encres tiennent le seuil sur son propre bandeau', () {
      // La vérification porte sur l'objet RÉELLEMENT passé au composant, pas
      // sur les constantes prises séparément : c'est leur assemblage qui est
      // peint, et c'est lui qui pourrait dériver.
      final tone = EnrollmentListingTones.table;
      expect(
        ratio(tone.headerInk, tone.header),
        greaterThanOrEqualTo(seuilTexte),
      );
      expect(
        ratio(tone.headerInkSorted, tone.header),
        greaterThanOrEqualTo(seuilTexte),
      );
    });
  });

  group('encres sur le bandeau de table', () {
    test('les deux encres d\'en-tête tiennent le seuil', () {
      final fond = EnrollmentListingTones.tableEntete;
      expect(
        ratio(EnrollmentListingTones.inkEnteteTable, fond),
        greaterThanOrEqualTo(seuilTexte),
        reason: 'encre d\'en-tête',
      );
      expect(
        ratio(EnrollmentListingTones.inkEnteteTri, fond),
        greaterThanOrEqualTo(seuilTexte),
        reason: 'encre de colonne triée',
      );
    });
  });

  group('encres sur les surfaces claires', () {
    test('l\'eyebrow terre cuite tient sur le fond de barre', () {
      expect(
        ratio(
          EnrollmentListingTones.inkTerreCuite,
          EnrollmentListingTones.barreFond,
        ),
        greaterThanOrEqualTo(seuilTexte),
      );
    });

    test('contre-épreuve E2 : la terre cuite claire ne tiendrait pas', () {
      // #B85C2C sur le voile de la pastille « niveau visé » : 4,04:1. C'est
      // tout l'objet du token assombri — si ce couple passe un jour, l'écart
      // n'a plus lieu d'être.
      expect(
        ratio(AppColors.terreCuite, const Color(0xFFFBEFE8)),
        lessThan(seuilTexte),
      );
    });

    test('le texte de la barre reste neutre et lisible', () {
      // La barre est teintée, son texte ne l'est pas : une surface colorée ne
      // colore pas ce qu'elle porte.
      expect(
        ratio(AppColors.textSecondary, EnrollmentListingTones.barreFond),
        greaterThanOrEqualTo(seuilTexte),
      );
    });

    test('les champs restent blancs sur le corps bleuté', () {
      // C'est le contraste de SURFACE qui dit « ici, on saisit ». On vérifie
      // qu'il existe, sans quoi la règle est décorative.
      expect(
        ratio(AppColors.surfaceRaised, EnrollmentListingTones.formulaireFond),
        greaterThan(1.02),
      );
    });
  });

  group('statuts', () {
    test('chaque couleur pleine tient sur son voile et sur le blanc', () {
      EnrollmentListingTones.statut.forEach((key, tone) {
        expect(
          ratio(tone.color, tone.soft),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'pastille « $key »',
        );
        expect(
          ratio(tone.color, AppColors.surfaceRaised),
          greaterThanOrEqualTo(seuilGraphique),
          reason: 'filet « $key » sur carte blanche',
        );
      });
    });

    test('un statut inconnu ne fabrique pas une couleur', () {
      expect(
        () => EnrollmentListingTones.statutOf('statut-inexistant'),
        throwsAssertionError,
      );
    });
  });

  group('la zébrure ne porte aucune information', () {
    test('son écart est infime, et c\'est voulu', () {
      // Si ce ratio montait, la liste deviendrait bicolore — ce que le §12
      // interdit explicitement. Le test borne donc par le HAUT.
      final r = ratio(EnrollmentListingTones.tableZebrure, AppColors.surface);
      expect(r, lessThan(1.2), reason: 'une zébrure guide, elle ne dit rien');
    });
  });
}
