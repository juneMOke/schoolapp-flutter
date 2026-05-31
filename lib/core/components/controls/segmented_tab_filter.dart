import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Option générique pour [SegmentedTabFilter].
class SegmentedTabOption<T> {
  final String label;
  final T value;

  const SegmentedTabOption({required this.label, required this.value});
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

  const SegmentedTabFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.enrollmentStatsPeriodFilterHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentStatsChartRadius,
        ),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) => _buildTab(opt)).toList(),
      ),
    );
  }

  Widget _buildTab(SegmentedTabOption<T> opt) {
    final isSelected = opt.value == selected;
    return GestureDetector(
      onTap: () => onSelected(opt.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingXS,
        ),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.enrollmentStatsAccent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.enrollmentStatsAccent.withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : const BoxDecoration(),
        child: Text(
          opt.label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
