import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class FinanceDetailKpiStrip extends StatelessWidget {
  final List<FinanceDetailKpiItem> items;

  const FinanceDetailKpiStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final children = items
            .map(
              (item) => _FinanceDetailKpiTile(
                key: ValueKey(item.label),
                item: item,
                expanded: !compact,
              ),
            )
            .toList(growable: false);

        if (compact) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last)
                  const SizedBox(height: AppDimensions.spacingS),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i < children.length - 1)
                const SizedBox(width: AppDimensions.spacingM),
            ],
          ],
        );
      },
    );
  }
}

class FinanceDetailKpiItem {
  final String label;
  final String value;
  final String? suffix;
  final Color valueColor;
  final Color? suffixColor;

  const FinanceDetailKpiItem({
    required this.label,
    required this.value,
    this.suffix,
    this.valueColor = AppColors.textPrimary,
    this.suffixColor,
  });
}

class _FinanceDetailKpiTile extends StatelessWidget {
  final FinanceDetailKpiItem item;
  final bool expanded;

  const _FinanceDetailKpiTile({
    super.key,
    required this.item,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTextStyles.totalAmountLora.copyWith(
      fontSize: 18,
      color: item.valueColor,
    );
    final effectiveSuffix = item.suffix?.trim();

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        if (effectiveSuffix == null || effectiveSuffix.isEmpty)
          Text(item.value, style: valueStyle)
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: item.value, style: valueStyle),
                TextSpan(
                  text: ' $effectiveSuffix',
                  style: valueStyle.copyWith(
                    color: item.suffixColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (!expanded) {
      return child;
    }

    return child;
  }
}
