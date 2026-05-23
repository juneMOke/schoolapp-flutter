import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_step_constants.dart';

class SummaryFieldGrid extends StatelessWidget {
  final List<SummaryField> items;

  const SummaryFieldGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth < enrollmentSummaryCompactBreakpoint;
        final columns = isCompact ? 1 : 2;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * AppDimensions.spacingM) /
            columns;

        return Wrap(
          spacing: AppDimensions.spacingM,
          runSpacing: AppDimensions.spacingS,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _SummaryFieldTile(item: item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _SummaryFieldTile extends StatelessWidget {
  final SummaryField item;

  const _SummaryFieldTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          item.value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
