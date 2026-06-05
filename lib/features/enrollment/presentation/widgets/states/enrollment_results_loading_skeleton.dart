import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

class EnrollmentResultsLoadingSkeleton extends StatelessWidget {
  final bool isGrid;
  final int itemCount;

  const EnrollmentResultsLoadingSkeleton({
    super.key,
    required this.isGrid,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.border;
    final highlight = AppColors.surfaceRaised;

    if (isGrid) {
      return EteeloGridView(
        itemCount: itemCount,
        minItemWidth: AppDimensions.gridMinItemWidth,
        spacing: AppSpacing.gridGap,
        padding: EdgeInsets.zero,
        itemBuilder: (_, _) =>
            _SkeletonCard(baseColor: baseColor, highlightColor: highlight),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == itemCount - 1 ? 0 : AppSpacing.md,
            ),
            child: _SkeletonRow(
              baseColor: baseColor,
              highlightColor: highlight,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;

  const _SkeletonCard({required this.baseColor, required this.highlightColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBlock(
            width: 84,
            height: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: AppSpacing.md),
          _SkeletonBlock(
            width: double.infinity,
            height: 14,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SkeletonBlock(
            width: 110,
            height: 10,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SkeletonBlock(
            width: 78,
            height: 22,
            baseColor: baseColor,
            highlightColor: highlightColor,
            borderRadius: AppRadius.brPill,
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;

  const _SkeletonRow({required this.baseColor, required this.highlightColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SkeletonBlock(
          width: 32,
          height: 32,
          baseColor: baseColor,
          highlightColor: highlightColor,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 22,
          child: _SkeletonBlock(
            height: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 10,
          child: _SkeletonBlock(
            height: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 12,
          child: _SkeletonBlock(
            height: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 12,
          child: _SkeletonBlock(
            height: 20,
            baseColor: baseColor,
            highlightColor: highlightColor,
            borderRadius: AppRadius.brPill,
          ),
        ),
      ],
    );
  }
}

class _SkeletonBlock extends StatefulWidget {
  final double? width;
  final double height;
  final Color baseColor;
  final Color highlightColor;
  final BorderRadius borderRadius;

  const _SkeletonBlock({
    this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    this.borderRadius = AppRadius.brSm,
  });

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.skeletonPulse,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: widget.borderRadius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final color =
            Color.lerp(widget.baseColor, widget.highlightColor, t) ??
            widget.baseColor;

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}
