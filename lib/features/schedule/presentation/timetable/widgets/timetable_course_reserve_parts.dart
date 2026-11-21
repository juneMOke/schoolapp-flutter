import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
export 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_reserve_line.dart';

/// L'en-tête de la réserve, sur un dégradé chaud : médaillon, titre et aide,
/// le compteur « 18/30 h » (à côté de la grille) ou « Voir ⌄ » (bandeau
/// replié), puis la barre de progression — verte quand tout est placé.
class ReserveHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? counter;
  final String? toggle;
  final bool open;
  final int placed;
  final int? planned;

  const ReserveHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.counter,
    required this.toggle,
    required this.open,
    required this.placed,
    required this.planned,
  });

  @override
  Widget build(BuildContext context) {
    final planned = this.planned;
    final complete = planned != null && placed >= planned;
    final share = planned == null || planned == 0
        ? 0.0
        : (placed / planned).clamp(0.0, 1.0);
    final counter = this.counter;
    final toggle = this.toggle;
    return Container(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.minTouchTarget,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.timetableWarmSurfaceDeep,
            AppColors.timetableWarmSurface,
          ],
        ),
        border: open
            ? const Border(
                bottom: BorderSide(color: AppColors.timetableWarmBorder),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppDimensions.timetableTileIcon,
                height: AppDimensions.timetableTileIcon,
                decoration: const BoxDecoration(
                  color: AppColors.terreCuite,
                  borderRadius: AppRadius.brSm,
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  size: AppSpacing.lg,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.bleuProfond,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (counter != null)
                Text(
                  counter,
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.codeMuted.copyWith(
                    fontWeight: FontWeight.w700,
                    color: complete
                        ? AppColors.vertSavane
                        : AppColors.timetableWarmInk,
                  ),
                ),
              if (toggle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: AppRadius.brPill,
                    border: Border.all(color: AppColors.timetableWarmBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        toggle,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.timetableWarmInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        open
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: AppSpacing.lg,
                        color: AppColors.timetableWarmInk,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ExcludeSemantics(
            child: _Progress(share: share, complete: complete),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final double share;
  final bool complete;

  const _Progress({required this.share, required this.complete});

  @override
  Widget build(BuildContext context) => Container(
    height: AppDimensions.timetableBarHeight,
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brPill,
      border: Border.all(color: AppColors.timetableWarmBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: share,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brPill,
            color: complete ? AppColors.vertSavane : null,
            gradient: complete
                ? null
                : const LinearGradient(
                    colors: [AppColors.orDoux, AppColors.terreCuite],
                  ),
          ),
        ),
      ),
    ),
  );
}
