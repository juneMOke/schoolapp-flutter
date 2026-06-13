import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Squelette de la zone de synthese : conserve la mise en page (zone teintee +
/// bande de cartes fantomes + barre). `role=status` via Semantics ; le shimmer
/// respecte reduced-motion (delegue a [EteeloSkeletonBox]).
class PresenceSummarySkeleton extends StatelessWidget {
  const PresenceSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.presenceLoadingA11yLabel,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AppDimensions.sectionCardRadius,
            ),
            border: Border.all(color: AppColors.border),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.presenceSummaryTintTop,
                AppColors.presenceSummaryTintBottom,
              ],
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(AppDimensions.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EteeloSkeletonBox(
                      width: AppDimensions.presenceMedallionSize,
                      height: AppDimensions.presenceMedallionSize,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppDimensions.presenceMedallionRadius),
                      ),
                    ),
                    SizedBox(width: AppDimensions.spacingS),
                    EteeloSkeletonBox(width: 150, height: 13),
                  ],
                ),
                SizedBox(height: AppDimensions.spacingM),
                Wrap(
                  spacing: AppDimensions.spacingM,
                  runSpacing: AppDimensions.spacingM,
                  children: [
                    _GhostKpiCard(),
                    _GhostKpiCard(),
                    _GhostKpiCard(),
                    _GhostKpiCard(),
                  ],
                ),
                SizedBox(height: AppDimensions.spacingM),
                EteeloSkeletonBox(
                  width: double.infinity,
                  height: AppDimensions.presenceDistributionBarHeight,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostKpiCard extends StatelessWidget {
  const _GhostKpiCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.enrollmentStatsKpiCardMinWidth,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(
            AppDimensions.enrollmentStatsChartRadius,
          ),
          border: const Border(
            left: BorderSide(color: AppColors.border, width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingM,
        ),
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
            EteeloSkeletonBox(width: 56, height: 18),
            SizedBox(height: AppDimensions.spacingXS),
            EteeloSkeletonBox(width: 80, height: 9),
          ],
        ),
      ),
    );
  }
}
