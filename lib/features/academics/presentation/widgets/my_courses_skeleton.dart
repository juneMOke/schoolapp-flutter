import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Squelette de chargement de la liste : conserve l'anatomie des accordéons
/// (carte + liséré + médaillon + chips + tuiles) pour préserver la mise en
/// page. Délègue le shimmer à [EteeloSkeletonBox] (reduced-motion respecté).
class MyCoursesSkeleton extends StatelessWidget {
  const MyCoursesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.myCoursesLoadingA11yLabel,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < 3; i++) ...[
              const _SkeletonCard(),
              if (i != 2) const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    // Même anatomie que l'accordéon : liséré gauche via fond + padding (pas de
    // Row `stretch`, incompatible avec une vue défilante).
    return const ClipRRect(
      borderRadius: AppRadius.brCard,
      child: ColoredBox(
        color: AppColors.border,
        child: Padding(
          padding: EdgeInsets.only(left: 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              border: Border(
                top: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      EteeloSkeletonBox(
                        width: 50,
                        height: 50,
                        borderRadius: AppRadius.brMd,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EteeloSkeletonBox(width: 160, height: 14),
                            SizedBox(height: AppSpacing.sm),
                            EteeloSkeletonBox(width: 90, height: 10),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      EteeloSkeletonBox(
                        width: 64,
                        height: 24,
                        borderRadius: AppRadius.brPill,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      EteeloSkeletonBox(
                        width: 24,
                        height: 24,
                        borderRadius: AppRadius.brPill,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: EteeloSkeletonBox(
                          height: 64,
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: EteeloSkeletonBox(
                          height: 64,
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
