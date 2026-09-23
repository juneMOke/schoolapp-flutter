import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card_parts.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';

/// Chrome de section d'un tableau de bord : carte surélevée, titre, contenu.
///
/// Le dépôt en comptait déjà trois quasi identiques — une par tableau de bord
/// (`EnrollmentStatsChartCard`, `FinanceStatsChartCard`, `AttendanceOverviewCard`).
/// Celle-ci est la version de socle, reprise de la meilleure des trois (celle
/// des présences : bordure, ombre douce, indice optionnel), augmentée d'un
/// **sous-titre** qui dit ce que la carte montre et d'une rangée d'**actions**
/// (exports) posée dans l'en-tête.
///
/// Les trois cartes existantes ne sont PAS migrées ici : leur convergence est
/// un chantier à part, à mener avec les tests de chaque écran sous la main.
///
/// ## Deux habillages
///
/// Sans [tone] — le défaut — la carte est **blanche**, exactement comme
/// auparavant. Avec un [tone], elle se **teinte** de cette couleur : fond,
/// bord, médaillon et filet en dérivent tous par formule, si bien que l'œil
/// retrouve une section à sa couleur avant d'avoir lu son titre.
class EteeloStatsCard extends StatelessWidget {
  /// Ce que la carte montre, en une phrase nominale.
  final String title;

  /// Précision sous le titre — « Où sont allés les élèves inscrits ». Sert à
  /// lever l'ambiguïté d'un titre court, pas à commenter le graphique.
  final String? subtitle;

  /// Indice discret poussé à droite du titre (ex. « 7 niveaux concernés »).
  final String? hint;

  /// Glyphe de tête, posé dans une pastille teintée à gauche du titre.
  ///
  /// Purement décoratif : le titre reste la seule source d'information, et
  /// l'icône est masquée aux lecteurs d'écran. Sans icône, la carte ne réserve
  /// aucune place — et ne monte aucun `Icon` dans l'arbre.
  final IconData? icon;

  /// Teinte du glyphe. Par défaut celle du [tone] quand la carte en porte un,
  /// sinon le bleu ardoise — l'accent de lecture historique.
  final Color? iconColor;

  /// Ton de la carte, ou `null` pour la carte blanche.
  ///
  /// Toutes les surfaces en dérivent : le fond à [toneStrength] %, le bord à
  /// trois fois cette force, le médaillon à [tonedMedallionVeilPercent] %. Rien
  /// n'est saisi à la main — c'est ce qui garantit qu'une carte ne puisse pas
  /// dériver de sa section.
  final Color? tone;

  /// Force du ton, en pourcentage de dilution dans le blanc.
  ///
  /// À force égale un carmin et un ocre ne pèsent pas pareil : on règle une
  /// densité **perçue**, pas un chiffre. Au-delà de [toneStrengthMax], la carte
  /// cesse d'être une surface neutre et concurrence les pavés de chiffres.
  final int toneStrength;

  /// Actions de l'en-tête — typiquement les exports. Vide par défaut : une
  /// carte sans export ne réserve aucune place pour des boutons absents.
  final List<Widget> actions;

  final Widget child;

  const EteeloStatsCard({
    super.key,
    required this.title,
    this.subtitle,
    this.hint,
    this.icon,
    this.iconColor,
    this.tone,
    this.toneStrength = 10,
    this.actions = const [],
    required this.child,
  }) : assert(
         toneStrength >= toneStrengthMin && toneStrength <= toneStrengthMax,
         'toneStrength hors plage : au-delà de $toneStrengthMax la carte '
         'concurrence les pavés, en deçà de $toneStrengthMin elle ne se '
         'distingue plus du blanc.',
       );

  /// Dilution de `iconColor` pour le fond de la pastille d'une carte blanche —
  /// même parti que la carte KPI, dont les pastilles voisinent dans la grille.
  static const double iconBadgeTintAlpha = 0.12;

  // ---- Carte teintée (spec couleurs §04) ----
  static const int toneStrengthMin = 4;
  static const int toneStrengthMax = 13;
  static const int tonedMedallionVeilPercent = 11;
  static const double tonedMedallionRingOpacity = 0.20;
  static const double tonedFiletStartOpacity = 0.38;
  static const double tonedFiletMidOpacity = 0.04;

  /// Le bord est toujours ~3× plus saturé que le fond, sans quoi la carte n'a
  /// plus de contour sur le fond de page.
  static const int _borderStrengthFactor = 3;

  Color get _background => tone == null
      ? AppColors.surfaceRaised
      : ColorMix.tint(AppColors.surfaceRaised, tone!, toneStrength);

  Color get _border => tone == null
      ? AppColors.border
      : ColorMix.tint(
          AppColors.border,
          tone!,
          (toneStrength * _borderStrengthFactor).clamp(16, 100),
        );

  double get _radius =>
      tone == null ? AppDimensions.cardRadius : AppDimensions.insSectionRadius;

  @override
  Widget build(BuildContext context) {
    final tone = this.tone;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _border),
        // Élévation douce, cohérente avec EteeloKpiCard : les panneaux ne
        // paraissent pas plats face aux cartes KPI ombrées de la même grille.
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EteeloStatsCardHeader(
            title: title,
            subtitle: subtitle,
            hint: hint,
            icon: icon,
            iconColor: iconColor ?? tone ?? AppColors.bleuArdoise,
            tone: tone,
            actions: actions,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // Sur une carte teintée, un simple écart ne sépare plus l'en-tête du
          // contenu : le filet reprend ce rôle.
          if (tone != null) ...[
            EteeloStatsCardFilet(tone: tone),
            const SizedBox(height: AppDimensions.spacingM),
          ],
          child,
        ],
      ),
    );
  }
}
