import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';

/// Option générique pour [SegmentedTabFilter].
class SegmentedTabOption<T> {
  final String label;
  final T value;
  final IconData? icon;
  final String? semanticLabel;

  const SegmentedTabOption({
    required this.label,
    required this.value,
    this.icon,
    this.semanticLabel,
  });
}

class SegmentedTabFilterStyle {
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry containerPadding;
  final double? itemWidth;
  final double? itemHeight;
  final double itemBorderRadius;
  final Color selectedBackgroundColor;
  final Color selectedForegroundColor;
  final Color unselectedForegroundColor;
  final List<BoxShadow> selectedShadow;

  const SegmentedTabFilterStyle({
    this.backgroundColor = AppColors.surfaceAlt,
    this.borderColor = AppColors.border,
    this.borderRadius = AppDimensions.enrollmentStatsChartRadius,
    this.containerPadding = const EdgeInsets.all(3),
    this.itemWidth,
    this.itemHeight,
    this.itemBorderRadius = 9,
    this.selectedBackgroundColor = AppColors.enrollmentStatsAccent,
    this.selectedForegroundColor = Colors.white,
    this.unselectedForegroundColor = AppColors.textSecondary,
    this.selectedShadow = const [
      BoxShadow(color: Color(0x2E1B4D6B), blurRadius: 4, offset: Offset(0, 2)),
    ],
  });

  static const kpi = SegmentedTabFilterStyle(
    selectedShadow: AppElevation.shadowKpi,
  );
}

/// Filtre à onglets segmentés générique.
///
/// Utilisation :
/// ```dart
/// SegmentedTabFilter<EnrollmentStatsPeriod>(
///   options: [...],
///   selected: state.selectedPeriod,
///   onSelected: (p) => context.read<EnrollmentStatsBloc>().add(...),
/// )
/// ```
class SegmentedTabFilter<T> extends StatelessWidget {
  final List<SegmentedTabOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String? semanticsLabel;
  final SegmentedTabFilterStyle style;

  const SegmentedTabFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.semanticsLabel,
    this.style = const SegmentedTabFilterStyle(),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticsLabel,
      child: Container(
        height: AppDimensions.enrollmentStatsPeriodFilterHeight,
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(style.borderRadius),
          border: Border.all(color: style.borderColor),
        ),
        padding: style.containerPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => _buildTab(opt)).toList(),
        ),
      ),
    );
  }

  Widget _buildTab(SegmentedTabOption<T> opt) {
    final isSelected = opt.value == selected;
    final semanticLabel = opt.semanticLabel ?? opt.label;
    final isIconOnly = opt.icon != null && opt.label.isEmpty;
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      label: semanticLabel.isEmpty ? null : semanticLabel,
      onTap: () => onSelected(opt.value),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(style.itemBorderRadius),
            onTap: () => onSelected(opt.value),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.outCurve,
              width: style.itemWidth,
              height: style.itemHeight,
              alignment: Alignment.center,
              padding: isIconOnly
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingXS,
                    ),
              decoration: isSelected
                  ? BoxDecoration(
                      color: style.selectedBackgroundColor,
                      borderRadius: BorderRadius.circular(
                        style.itemBorderRadius,
                      ),
                      boxShadow: style.selectedShadow,
                    )
                  : const BoxDecoration(),
              child: _buildTabContent(opt, isSelected),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(SegmentedTabOption<T> opt, bool isSelected) {
    final color = isSelected
        ? style.selectedForegroundColor
        : style.unselectedForegroundColor;
    final textStyle = AppTextStyles.caption.copyWith(
      color: color,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    );

    if (opt.icon != null && opt.label.isEmpty) {
      return Icon(opt.icon, size: 18, color: color);
    }

    if (opt.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(opt.icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              opt.label,
              style: textStyle,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      opt.label,
      style: textStyle,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }
}
