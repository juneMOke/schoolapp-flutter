/// Les silhouettes d'attente d'un tableau de bord.
///
/// Un rond qui tourne ne dit rien de ce qui arrive : l'écran saute d'un
/// indicateur centré à une grille dense, et la page se réagence sous l'œil.
/// Ces trois blocs occupent **les mêmes places** que les composants qu'ils
/// remplacent, pour que l'arrivée des données ne déplace rien.
///
/// Le pouls respecte `prefers-reduced-motion` — c'est `EteeloSkeletonBox` qui
/// s'en charge, aucun appelant n'a à le redemander.
///
/// L'annonce aux lecteurs d'écran (`liveRegion` + libellé) appartient à la vue
/// qui assemble ces blocs, pas à chaque bloc : trois annonces pour un seul
/// chargement se liraient comme trois chargements.
library;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Ombre douce commune aux cartes, alignée sur [EteeloStatsCard] et
/// `EteeloKpiCard`.
List<BoxShadow> get _cardShadow => [
  BoxShadow(
    color: AppColors.textPrimary.withValues(alpha: 0.04),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

/// La bande de cartes d'indicateurs, à sa grille exacte.
///
/// Réutilise [EteeloKpiBand.columnsFor] plutôt que de recalculer un
/// enroulement : deux formules qui divergeraient feraient sauter la grille au
/// moment précis où les chiffres apparaissent.
class EteeloKpiBandSkeleton extends StatelessWidget {
  /// Nombre de cartes attendues — celui que la vue chargée affichera.
  final int count;

  /// Hauteur d'une carte. Les cartes à sous-ligne sont plus hautes.
  final double cardHeight;

  const EteeloKpiBandSkeleton({
    super.key,
    required this.count,
    this.cardHeight = AppDimensions.kpiCardHeightWithSubline,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppDimensions.spacingM;
        final columns = EteeloKpiBand.columnsFor(constraints.maxWidth, count);
        final cardWidth =
            ((constraints.maxWidth - gap * (columns - 1)) / columns)
                .floorToDouble();

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: cardWidth,
                child: _GhostKpiCard(height: cardHeight),
              ),
          ],
        );
      },
    );
  }
}

/// Une carte d'indicateur : liséré d'accent, pastille d'icône, valeur, sous-ligne.
class _GhostKpiCard extends StatelessWidget {
  final double height;

  const _GhostKpiCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentStatsChartRadius,
        ),
        border: const Border(
          left: BorderSide(color: AppColors.border, width: 3),
        ),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EteeloSkeletonBox(
            width: 26,
            height: 26,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          SizedBox(height: AppDimensions.spacingS),
          EteeloSkeletonBox(width: 64, height: 18),
          SizedBox(height: AppDimensions.spacingXS),
          EteeloSkeletonBox(width: 88, height: 9),
        ],
      ),
    );
  }
}

/// Une carte de section portant un graphique : titre fantôme, puis le tracé.
class EteeloChartSkeleton extends StatelessWidget {
  /// Hauteur de la zone de tracé — celle du graphique qui va s'y poser.
  final double chartHeight;

  const EteeloChartSkeleton({
    super.key,
    this.chartHeight = AppDimensions.enrollmentStatsChartSectionHeight,
  });

  @override
  Widget build(BuildContext context) {
    return _GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EteeloSkeletonBox(width: 160, height: 14),
          const SizedBox(height: AppDimensions.spacingM),
          EteeloSkeletonBox(
            width: double.infinity,
            height: chartHeight,
            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          ),
        ],
      ),
    );
  }
}

/// Un classement en lignes-barres.
///
/// Les largeurs **décroissent** d'une ligne à l'autre. Ce n'est pas un
/// ornement : le bloc qui va s'y substituer est trié par effectif décroissant,
/// et une pile de barres égales annoncerait une répartition uniforme que les
/// données démentiront une demi-seconde plus tard.
class EteeloBarRowsSkeleton extends StatelessWidget {
  final int rows;

  /// Largeur de la colonne des libellés, celle de [EteeloBarRows].
  final double labelWidth;

  const EteeloBarRowsSkeleton({
    super.key,
    this.rows = 5,
    this.labelWidth = AppDimensions.enrollmentDashboardRowLabelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return _GhostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EteeloSkeletonBox(width: 160, height: 14),
          const SizedBox(height: AppDimensions.spacingM),
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: const EteeloSkeletonBox(width: 84, height: 10),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  // 100 %, 80 %, 64 %… : la décroissance d'un classement.
                  flex: (100 * _decay(i)).round(),
                  child: EteeloSkeletonBox(
                    height: AppDimensions.enrollmentDashboardRowBarHeight,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.enrollmentDashboardPillRadius,
                    ),
                  ),
                ),
                // Ce qui reste de la largeur, laissé vide.
                Spacer(flex: (100 * (1 - _decay(i))).round().clamp(1, 100)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Part de largeur de la barre du rang [index].
  static double _decay(int index) => 1 / (1 + index * 0.25);
}

/// Le chrome d'une carte de section, sans son contenu.
class _GhostCard extends StatelessWidget {
  final Widget child;

  const _GhostCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: child,
    );
  }
}
