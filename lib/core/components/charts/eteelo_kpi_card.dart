import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Carte KPI générique affichant un indicateur chiffré avec accent couleur.
class EteeloKpiCard extends StatelessWidget {
  final EteeloKpiCardData data;

  const EteeloKpiCard({super.key, required this.data});

  /// Le tour d'une carte enfoncée. Transparent au repos : le rendu des cartes
  /// de lecture ne bouge pas d'un pixel.
  static BorderSide _edge(EteeloKpiCardData data) =>
      data.selected ? BorderSide(color: data.accent) : BorderSide.none;

  @override
  Widget build(BuildContext context) {
    final values = data.displayValues;
    final extraValues = values.length - 1;
    final baseHeight = data.subline != null
        ? AppDimensions.kpiCardHeightWithSubline
        : AppDimensions.enrollmentStatsKpiCardHeight;

    final card = Container(
      // Une hauteur PLANCHER, jamais une hauteur fixe. La carte garde son
      // gabarit historique quand le contenu y tient, et grandit quand il n'y
      // tient plus — un second montant, une police agrandie par le téléphone.
      // Fixée d'avance, elle débordait : chaque montant de plus lui ajoutait
      // 22 px, pour une ligne en gras 24 qui en occupe davantage.
      constraints: BoxConstraints(
        minWidth: AppDimensions.enrollmentStatsKpiCardMinWidth,
        minHeight:
            baseHeight + extraValues * AppDimensions.kpiCardExtraValueHeight,
      ),
      // Le contenu reste centré verticalement dans le plancher, comme avant.
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.enrollmentStatsCardSurface,
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentStatsChartRadius,
        ),
        border: Border(
          left: BorderSide(color: data.accent, width: 3),
          // Enfoncée : le tour de la carte reprend l'accent. Jamais la couleur
          // seule — l'état est aussi annoncé, et la valeur reste écrite.
          top: _edge(data),
          right: _edge(data),
          bottom: _edge(data),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: Column(
        // `min` : la hauteur vient du contenu, le plancher du `Container`.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingXS),
                decoration: BoxDecoration(
                  color: data.accentSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(data.icon, size: 14, color: data.accent),
              ),
              const Spacer(),
              if (data.percent != null)
                Text(
                  '${data.percent} %',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          // Une valeur par ligne. `scaleDown` ne réduit que si la largeur
          // manque, donc les compteurs entiers courts restent inchangés — et
          // deux devises gardent chacune sa taille pleine au lieu d'être
          // rétrécies ensemble sur une ligne unique.
          for (final value in values)
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.pageTitle.copyWith(
                    color: data.accent,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ),
            ),
          // Sans sous-ligne : label sur deux lignes au plus. Avec sous-ligne :
          // label compact (1 ligne) + sous-ligne discrète (ex. « 510
          // élève-jours »), sur une carte plus haute.
          if (data.subline == null)
            Text(
              data.label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          else ...[
            Text(
              data.label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              data.subline!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    final tapped = _wrapTap(card);

    // reduced-motion : pas d'animation d'entree (etat final visible).
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return tapped;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${data.label}-${data.displayValue}-${data.percent}'),
      tween: Tween(begin: 0.97, end: 1),
      duration: AppMotion.standard,
      curve: AppMotion.outCurve,
      builder: (context, scale, child) => Opacity(
        opacity: scale,
        child: Transform.scale(scale: scale, child: child),
      ),
      child: tapped,
    );
  }

  /// N'enveloppe que les cartes qui **font** quelque chose : l'arbre d'une
  /// carte de lecture reste exactement celui d'avant.
  Widget _wrapTap(Widget card) {
    final onTap = data.onTap;
    if (onTap == null) return card;

    return Semantics(
      button: true,
      selected: data.selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentStatsChartRadius,
        ),
        child: card,
      ),
    );
  }
}
