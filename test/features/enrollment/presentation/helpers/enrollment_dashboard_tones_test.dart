import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_dashboard_tones.dart';

/// Test de non-régression de contraste du tableau de bord des inscriptions,
/// réclamé par le §11 de la spec couleurs.
///
/// Il ne vérifie pas seulement que l'écran est conforme : il **fige les quatre
/// écarts assumés** à la spec, chacun avec sa contre-épreuve. Si une de ces
/// contre-épreuves devient verte, c'est que la spec a changé au point que
/// l'écart n'a plus lieu d'être — et le test le dira au lieu de laisser la
/// divergence dormir.
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

  Color voile(Color fond, Color ink, double alpha) =>
      Color.alphaBlend(ink.withValues(alpha: alpha), fond);

  group('fidélité aux valeurs publiées par la spec', () {
    test('pave() reproduit les trois fonds de pavé', () {
      expect(
        hex(EnrollmentDashboardTones.pave(AppColors.bleuArdoise)),
        '#184662',
      );
      expect(
        hex(EnrollmentDashboardTones.pave(AppColors.vertSavane)),
        '#335D48',
      );
      expect(hex(EnrollmentDashboardTones.pave(AppColors.insOcre)), '#855D0F');
    });

    test('teinte() reproduit les six fonds de section', () {
      const attendus = {
        'rythme': '#E8EDF0',
        'sexe': '#F6EAEF',
        'type': '#F9F0EC',
        'niveau': '#ECF0ED',
        'cycle': '#F6F0E6',
        'jour': '#ECEEF0',
      };
      EnrollmentDashboardTones.sectionTone.forEach((key, entry) {
        final (tone, strength) = entry;
        expect(
          hex(EnrollmentDashboardTones.teinte(tone, strength)),
          attendus[key],
          reason: 'section « $key »',
        );
      });
    });

    test('toutes les forces restent dans la plage autorisée', () {
      EnrollmentDashboardTones.sectionTone.forEach((key, entry) {
        final (_, strength) = entry;
        expect(
          strength,
          inInclusiveRange(
            EnrollmentDashboardTones.toneStrengthMin,
            EnrollmentDashboardTones.toneStrengthMax,
          ),
          reason: 'section « $key »',
        );
      });
    });
  });

  group('encres sur les pavés de chiffres clés', () {
    test('les trois encres tiennent le seuil sur les quatre pavés', () {
      EnrollmentDashboardTones.kpiAccent.forEach((key, accent) {
        final fond = EnrollmentDashboardTones.pave(accent);
        for (final (nom, ink) in [
          ('valeur', AppColors.insInkMain),
          ('libellé', AppColors.insInkLabel),
          ('sous-ligne', AppColors.insInkSub),
        ]) {
          expect(
            ratio(ink, fond),
            greaterThanOrEqualTo(seuilTexte),
            reason: '$nom du pavé « $key » sur $fond',
          );
        }
      });
    });
  });

  group('textes sur les cartes de section teintées', () {
    test('titre et sous-titre tiennent le seuil sur les six cartes', () {
      for (final key in EnrollmentDashboardTones.sectionTone.keys) {
        final (fond, _) = EnrollmentDashboardTones.sectionSurface(key);
        for (final (nom, ink) in [
          ('titre', AppColors.textPrimary),
          ('sous-titre', AppColors.textSecondary),
        ]) {
          expect(
            ratio(ink, fond),
            greaterThanOrEqualTo(seuilTexte),
            reason: '$nom de la section « $key »',
          );
        }
      }
    });

    test('le glyphe du médaillon se détache de son voile', () {
      EnrollmentDashboardTones.sectionTone.forEach((key, entry) {
        final (tone, _) = entry;
        final voileMedaillon = EnrollmentDashboardTones.teinte(
          tone,
          EteeloStatsCard.tonedMedallionVeilPercent,
        );
        expect(
          ratio(tone, voileMedaillon),
          greaterThanOrEqualTo(seuilGraphique),
          reason: 'médaillon de la section « $key »',
        );
      });
    });

    test('le gris des étiquettes d\'axe tient sur une carte teintée', () {
      for (final key in EnrollmentDashboardTones.sectionTone.keys) {
        final (fond, _) = EnrollmentDashboardTones.sectionSurface(key);
        expect(
          ratio(AppColors.textMutedAa, fond),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'étiquettes d\'axe sur « $key »',
        );
      }
    });
  });

  group('A1 · les remplissages de barre sont des aplats pleins', () {
    /// Les deux cartes sur lesquelles une ventilation est peinte.
    final cartesDeBarres = [
      EnrollmentDashboardTones.sectionSurface('cycle').$1,
      EnrollmentDashboardTones.sectionSurface('niveau').$1,
      EnrollmentDashboardTones.sectionSurface('rythme').$1,
    ];

    test('chaque couleur de donnée se détache de chaque carte porteuse', () {
      for (final carte in cartesDeBarres) {
        for (final couleur in EnrollmentDashboardTones.barColors) {
          final peinte = voile(
            carte,
            couleur,
            EnrollmentDashboardTones.barFillOpacity,
          );
          expect(
            ratio(peinte, carte),
            greaterThanOrEqualTo(seuilGraphique),
            reason: '${hex(couleur)} sur $carte',
          );
        }
      }
    });

    test('contre-épreuve : le dégradé .34 de la spec ne tiendrait pas', () {
      final carte = EnrollmentDashboardTones.sectionSurface('rythme').$1;
      final bas = voile(carte, AppColors.bleuArdoise, 0.34);
      expect(
        ratio(bas, carte),
        lessThan(seuilGraphique),
        reason:
            'si ce couple passe désormais, le dégradé de la spec peut revenir',
      );
    });
  });

  group('A2/A3 · l\'or ne colore aucune donnée', () {
    test('l\'or est absent des trois tables de données', () {
      expect(
        EnrollmentDashboardTones.barColors,
        isNot(contains(AppColors.orDoux)),
        reason: 'l\'or plafonne à 2,01:1 en barre — il reste un glyphe',
      );
    });

    test('contre-épreuve : l\'or ne tiendrait pas sur la carte « cycle »', () {
      final carte = EnrollmentDashboardTones.sectionSurface('cycle').$1;
      expect(
        ratio(AppColors.orDoux, carte),
        lessThan(seuilGraphique),
        reason: 'si l\'or passe désormais, Maternelle peut le reprendre',
      );
    });
  });

  group('bandeau d\'effectif — encres sur le dégradé', () {
    // Le dégradé va du bleu profond au bleu ardoise éclairci : c'est
    // l'extrémité CLAIRE qui contraint, puisque les encres y sont crème.
    const extremiteClaire = AppColors.bleuArdoiseLight;

    test('les trois encres tiennent sur l\'extrémité la plus claire', () {
      for (final (nom, ink) in [
        ('total', AppColors.insInkMain),
        ('unité', AppColors.insInkUnit),
        ('méta', AppColors.insInkMeta),
      ]) {
        expect(
          ratio(ink, extremiteClaire),
          greaterThanOrEqualTo(seuilTexte),
          reason: '$nom du bandeau',
        );
      }
    });

    test('l\'or du sur-titre n\'est lisible qu\'à gauche', () {
      // Il est ancré sur l'extrémité sombre, et doit y rester : c'est la
      // raison pour laquelle le sur-titre ne se centre pas.
      expect(
        ratio(AppColors.orDoux, AppColors.bleuProfond),
        greaterThanOrEqualTo(seuilTexte),
      );
      expect(
        ratio(AppColors.orDoux, extremiteClaire),
        lessThan(seuilTexte),
        reason: 'si l\'or passait partout, la contrainte d\'ancrage tomberait',
      );
    });
  });

  group('A5 · les deux ratios que la spec annonce faux', () {
    test('le delta vert sur pavé bleu est bien pire qu\'annoncé', () {
      final paveBleu = EnrollmentDashboardTones.pave(AppColors.bleuArdoise);
      final mesure = ratio(AppColors.vertSavane, paveBleu);
      // La spec §10 annonce 2,6:1 ; la mesure donne 1,63:1. Son interdit est
      // donc encore mieux fondé qu'elle ne le croit.
      expect(mesure, lessThan(2.0));
    });

    test('l\'onglet actif est au-dessus de ce que la spec annonce', () {
      // Annoncé 8,6:1 au §08, mesuré 9,05:1 — la spec sous-estime.
      expect(
        ratio(AppColors.surfaceRaised, AppColors.bleuArdoise),
        greaterThan(8.8),
      );
    });
  });
}
