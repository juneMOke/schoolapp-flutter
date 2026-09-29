import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_state.dart';

/// Le premier chargement, à la géométrie réelle de l'affichage choisi : huit
/// cartes en grille, huit lignes en liste. Le mouvement réduit est respecté
/// par les squelettes du socle.
class StaffFileSkeleton extends StatelessWidget {
  final StaffViewMode viewMode;

  const StaffFileSkeleton({super.key, required this.viewMode});

  static const int _count = 8;

  @override
  Widget build(BuildContext context) {
    if (viewMode == StaffViewMode.list) {
      return const EteeloListSkeleton(rowCount: _count, pillCount: 3);
    }
    return Semantics(
      container: true,
      liveRegion: true,
      child: EteeloGridView(
        padding: EdgeInsets.zero,
        minItemWidth: AppDimensions.staffCardMinWidth,
        itemCount: _count,
        itemBuilder: (_, _) => const _CardGhost(),
      ),
    );
  }
}

class _CardGhost extends StatelessWidget {
  const _CardGhost();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brCard,
      border: Border.all(color: AppColors.border),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            EteeloSkeletonBox(
              width: 52,
              height: 52,
              borderRadius: AppRadius.brPill,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EteeloSkeletonBox(height: 14),
                  SizedBox(height: AppSpacing.sm),
                  EteeloSkeletonBox(width: 90, height: 10),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        EteeloSkeletonBox(
          width: 120,
          height: 20,
          borderRadius: AppRadius.brPill,
        ),
      ],
    ),
  );
}
