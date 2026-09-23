import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module_tone.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_module_tones.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';

/// Test de non-régression de contraste réclamé par la spec Accueil-Couleurs
/// §10 : « un test unitaire calcule le ratio encre/fond de chaque entrée de
/// `moduleTones` et échoue sous 4,5:1 ».
///
/// Il n'existe pas pour la forme. Les valeurs du §02 et du §06, prises telles
/// quelles, **échouaient** : c'est ce test qui a fait apparaître la
/// contradiction entre le seuil posé au §04 et les voiles du §06, et c'est lui
/// qui empêche de revenir en arrière sans s'en apercevoir.
void main() {
  /// Seuil WCAG AA du texte courant. Aucun texte de pavé n'atteint la taille
  /// « titre » qui autoriserait 3:1 (§04).
  const seuil = 4.5;

  /// Ratio de contraste WCAG entre deux couleurs opaques.
  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Surface obtenue en posant un voile de blanc cassé sur le fond d'un pavé —
  /// exactement ce que fait la pastille. On mesure sur la surface COMPOSÉE :
  /// mesurer sur le fond nu serait plus indulgent, puisque le voile éclaircit
  /// et rapproche donc la surface de l'encre crème.
  Color voile(Color fond, double alpha) => Color.alphaBlend(
    AppColors.accueilBlocInkMain.withValues(alpha: alpha),
    fond,
  );

  /// Les cinq fonds que la spec autorise, et eux seuls (§01, §09).
  ///
  /// `final` et non `const` : `Color` surcharge `==`, ce que l'analyseur
  /// refuse dans un ensemble constant.
  final paletteFermee = <Color>{
    AppColors.accueilBlocBleuProfond,
    AppColors.accueilBlocBleuEncre,
    AppColors.accueilBlocBleuArdoise,
    AppColors.accueilBlocBleuArdoiseB,
    AppColors.accueilBlocTerreFoncee,
  };

  void pourChaqueTeinte(void Function(String, AccueilModuleTone) verifier) {
    AccueilModuleTones.table.forEach(verifier);
  }

  group('encres posées directement sur le fond du pavé', () {
    test('le titre du module tient le seuil', () {
      pourChaqueTeinte((id, tone) {
        expect(
          ratio(AppColors.accueilBlocInkMain, tone.background),
          greaterThanOrEqualTo(seuil),
          reason: 'titre du module « $id »',
        );
      });
    });

    test('la description tient le seuil', () {
      pourChaqueTeinte((id, tone) {
        expect(
          ratio(AppColors.accueilBlocInkBody, tone.background),
          greaterThanOrEqualTo(seuil),
          reason: 'description du module « $id »',
        );
      });
    });

    test('le « N pages » tient le seuil', () {
      pourChaqueTeinte((id, tone) {
        expect(
          ratio(AppColors.accueilBlocInkMeta, tone.background),
          greaterThanOrEqualTo(seuil),
          reason: 'méta du module « $id »',
        );
      });
    });
  });

  group('libellés de pastille, posés sur un voile', () {
    test('la pastille ordinaire tient le seuil au repos comme au survol', () {
      pourChaqueTeinte((id, tone) {
        for (final alpha in const [
          AccueilUiTokens.blocPillVeil,
          AccueilUiTokens.blocPillHoverVeil,
        ]) {
          expect(
            ratio(AppColors.accueilBlocInkMain, voile(tone.background, alpha)),
            greaterThanOrEqualTo(seuil),
            reason: 'pastille ordinaire de « $id » sous voile $alpha',
          );
        }
      });
    });

    test(
      'la pastille « Tableau de bord » tient le seuil dans les deux états',
      () {
        pourChaqueTeinte((id, tone) {
          for (final alpha in const [
            AccueilUiTokens.blocPillDashboardVeil,
            AccueilUiTokens.blocPillHoverVeil,
          ]) {
            expect(
              ratio(
                AppColors.accueilBlocAccentCreme,
                voile(tone.background, alpha),
              ),
              greaterThanOrEqualTo(seuil),
              reason: 'pastille Tableau de bord de « $id » sous voile $alpha',
            );
          }
        });
      },
    );
  });

  group('intégrité de la palette', () {
    test('aucun fond ne sort des cinq valeurs autorisées', () {
      pourChaqueTeinte((id, tone) {
        expect(
          paletteFermee,
          contains(tone.background),
          reason:
              'le module « $id » introduit un sixième fond — dix teintes, '
              'c\'est plus aucune hiérarchie (§09)',
        );
      });
    });

    test('l\'accent suit la famille : or sur bleu, crème sur terre cuite', () {
      pourChaqueTeinte((id, tone) {
        final attendu = tone.family == AccueilModuleFamily.bleu
            ? AppColors.accueilBlocAccentOr
            : AppColors.accueilBlocAccentCreme;
        expect(tone.accent, attendu, reason: 'accent du module « $id »');
      });
    });

    test('un module inconnu ne fabrique pas une couleur', () {
      // En debug l'assertion saute — c'est une erreur de programmation, pas un
      // cas d'exécution : la palette est fermée, il n'y a rien à inventer.
      expect(
        () => AccueilModuleTones.of('module-qui-nexiste-pas'),
        throwsAssertionError,
      );
    });
  });

  /// Garde-fou explicite sur les deux écarts assumés vis-à-vis de la spec. Ils
  /// sont documentés dans `AccueilModuleTones` et `AccueilUiTokens` ; ce test
  /// existe pour qu'un retour « à la lettre de la spec », fait de bonne foi,
  /// ne passe pas inaperçu.
  group('pourquoi la spec n\'est pas suivie à la lettre', () {
    test('le #8F421E du §02 ne tiendrait pas le seuil', () {
      const terreDeLaSpec = Color(0xFF8F421E);
      final auRepos = ratio(
        AppColors.accueilBlocAccentCreme,
        voile(terreDeLaSpec, AccueilUiTokens.blocPillDashboardVeil),
      );

      expect(
        auRepos,
        lessThan(seuil),
        reason:
            'si ce couple passe désormais, l\'écart de terre cuite n\'a plus '
            'lieu d\'être et le token peut revenir au #8F421E de la spec',
      );
    });

    test('le voile de survol .24 du §06 ne tiendrait pas le seuil', () {
      const voileDeLaSpec = 0.24;
      final surArdoise = ratio(
        AppColors.accueilBlocAccentCreme,
        voile(AppColors.accueilBlocBleuArdoise, voileDeLaSpec),
      );

      expect(
        surArdoise,
        lessThan(seuil),
        reason:
            'si ce couple passe désormais, le voile de survol peut remonter '
            'au .24 de la spec',
      );
    });
  });
}
