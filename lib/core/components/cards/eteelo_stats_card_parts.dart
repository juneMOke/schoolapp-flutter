import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';

/// En-tête d'une carte de section : titre, sous-titre, indice et actions.
///
/// Le titre et les actions s'enroulent l'un sous l'autre quand la carte est
/// trop étroite : sur un export à deux boutons de 44 dp, une rangée rigide
/// écraserait le titre jusqu'à l'ellipse dès la tablette en portrait.
class EteeloStatsCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? hint;
  final IconData? icon;
  final Color iconColor;

  /// Ton de la carte, ou `null` pour une carte blanche. Seule la **géométrie**
  /// du médaillon en dépend : teinté il passe à 34 dp avec un liseré interne,
  /// blanc il reste la pastille de 16 dp d'origine.
  final Color? tone;

  final List<Widget> actions;

  const EteeloStatsCardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.tone,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            // Jamais teinté : deux porteurs de couleur dans le même en-tête,
            // et la hiérarchie disparaît. Seul le médaillon porte le ton.
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            subtitle!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );

    // La pastille est décorative : le titre dit déjà tout, et la relire
    // n'ajouterait qu'un « icône » sans objet dans le flux du lecteur d'écran.
    final heading = icon == null
        ? texts
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: _Medallion(icon: icon!, color: iconColor, tone: tone),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Flexible(child: texts),
            ],
          );

    final trailing = <Widget>[
      if (hint != null)
        Text(
          hint!,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ...actions,
    ];

    if (trailing.isEmpty) {
      return SizedBox(width: double.infinity, child: heading);
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingS,
      children: [
        heading,
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingXS,
          children: trailing,
        ),
      ],
    );
  }
}

/// Pastille d'icône — deux géométries, selon que la carte porte un ton.
class _Medallion extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? tone;

  const _Medallion({
    required this.icon,
    required this.color,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final tone = this.tone;
    if (tone == null) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXS),
        decoration: BoxDecoration(
          color: color.withValues(alpha: EteeloStatsCard.iconBadgeTintAlpha),
          borderRadius: BorderRadius.circular(
            AppDimensions.statsCardIconBadgeRadius,
          ),
        ),
        child: Icon(icon, size: AppDimensions.statsCardIconSize, color: color),
      );
    }

    return Container(
      width: AppDimensions.insSectionMedallionSize,
      height: AppDimensions.insSectionMedallionSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorMix.tint(
          AppColors.surfaceRaised,
          tone,
          EteeloStatsCard.tonedMedallionVeilPercent,
        ),
        borderRadius: BorderRadius.circular(
          AppDimensions.insSectionMedallionRadius,
        ),
        border: Border.all(
          color: tone.withValues(
            alpha: EteeloStatsCard.tonedMedallionRingOpacity,
          ),
        ),
      ),
      child: Icon(
        icon,
        size: AppDimensions.insSectionMedallionIconSize,
        color: color,
      ),
    );
  }
}

/// Filet de séparation sous l'en-tête d'une carte teintée : 1 dp qui part du
/// ton et s'efface vers la droite. Il remplace le vide entre l'en-tête et le
/// contenu — sur une carte teintée, un simple écart ne sépare plus rien.
class EteeloStatsCardFilet extends StatelessWidget {
  final Color tone;

  const EteeloStatsCardFilet({super.key, required this.tone});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.insSectionFiletHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tone.withValues(alpha: EteeloStatsCard.tonedFiletStartOpacity),
              tone.withValues(alpha: EteeloStatsCard.tonedFiletMidOpacity),
              Colors.transparent,
            ],
            stops: const [0, AppDimensions.insSectionFiletFadeStop, 1],
          ),
        ),
      ),
    );
  }
}
