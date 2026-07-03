import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Squelette de chargement de la page détail (spec §11) : conserve la mise en
/// page (en-tête + onglets + tableau). Délègue le shimmer à [EteeloSkeletonBox]
/// (reduced-motion respecté).
class CoursDetailSkeleton extends StatelessWidget {
  const CoursDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.courseDetailLoadingA11yLabel,
      liveRegion: true,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSkeleton(),
          SizedBox(height: AppSpacing.lg),
          _TabsSkeleton(),
          SizedBox(height: AppSpacing.md),
          _PanelSkeleton(),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EteeloSkeletonBox(width: 54, height: 54),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EteeloSkeletonBox(width: 180, height: 18),
                SizedBox(height: AppSpacing.sm),
                EteeloSkeletonBox(width: 120, height: 12),
                SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    EteeloSkeletonBox(width: 72, height: 22),
                    EteeloSkeletonBox(width: 90, height: 22),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabsSkeleton extends StatelessWidget {
  const _TabsSkeleton();

  @override
  Widget build(BuildContext context) {
    // Boîte pleine largeur : neutre vis-à-vis du nombre réel d'onglets de
    // période (calculé en responsive par CoursPeriodeTabs), pour ne pas
    // annoncer une grille que le contenu ne respecterait pas.
    return const EteeloSkeletonBox(height: 56, borderRadius: AppRadius.brLg);
  }
}

class _PanelSkeleton extends StatelessWidget {
  const _PanelSkeleton();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              EteeloSkeletonBox(
                width: 42,
                height: 42,
                borderRadius: AppRadius.brPill,
              ),
              SizedBox(width: AppSpacing.md),
              EteeloSkeletonBox(width: 160, height: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const EteeloSkeletonBox(height: 52, borderRadius: AppRadius.brMd),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < 3; i++) ...[
            const Row(
              children: [
                EteeloSkeletonBox(
                  width: 36,
                  height: 36,
                  borderRadius: AppRadius.brMd,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(child: EteeloSkeletonBox(height: 12)),
                SizedBox(width: AppSpacing.md),
                EteeloSkeletonBox(
                  width: 64,
                  height: 22,
                  borderRadius: AppRadius.brPill,
                ),
              ],
            ),
            if (i < 2) const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
