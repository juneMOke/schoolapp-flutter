import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FinanceStatsKpiBand extends StatelessWidget {
  final FinanceKpis kpis;
  final FeeTypeDistribution distribution;

  const FinanceStatsKpiBand({
    super.key,
    required this.kpis,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalByFeeType = distribution.items.fold<int>(0, (sum, e) => sum + e.expected);

    final items = [
      _KpiCellData(
        label: l10n.financeStatsKpiCollected,
        value: _formatCents(kpis.collected),
        valueColor: AppColors.bleuProfond,
        valueFontSize: AppDimensions.financeStatsKpiPrimaryValueFontSize,
      ),
      _KpiCellData(
        label: l10n.financeStatsKpiExpected,
        value: _formatCents(kpis.expected),
        subtitle: l10n.financeStatsPercentOfTotal(
          _safePercent(value: kpis.expected, total: totalByFeeType),
        ),
      ),
      _KpiCellData(
        label: l10n.financeStatsKpiOutstanding,
        value: _formatCents(kpis.outstanding),
        subtitle: l10n.financeStatsPercentOfTotal(
          _safePercent(value: kpis.outstanding, total: totalByFeeType),
        ),
      ),
      _KpiCellData(
        label: l10n.financeStatsKpiCollectionRate,
        value: '${kpis.collectionRate}%',
        valueColor: AppColors.warning,
      ),
    ];

    return Semantics(
      container: true,
      label: l10n.financeStatsKpiBandA11yLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
          if (constraints.maxWidth < 780) {
            final useSingleColumn = constraints.maxWidth < 480;
            final availableWidth = useSingleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - AppDimensions.spacingM) / 2;
            final safeWidth = availableWidth < 220 ? constraints.maxWidth : availableWidth;

            return Wrap(
              spacing: AppDimensions.spacingM,
              runSpacing: AppDimensions.spacingM,
              children: [
                for (final item in items)
                  SizedBox(
                    width: safeWidth,
                    child: _FinanceStatsKpiCell(data: item),
                  ),
              ],
            );
          }

            return Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Expanded(child: _FinanceStatsKpiCell(data: items[i])),
                  if (i < items.length - 1)
                    Container(
                      width: 1,
                      height: AppDimensions.financeStatsKpiDividerHeight,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingM,
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatCents(int amountInCents) {
    return formatMonetaryAmount(amountInCents / 100);
  }

  int _safePercent({required int value, required int total}) {
    if (total <= 0) return 0;
    return ((value * 100) / total).round();
  }
}

class _KpiCellData {
  final String label;
  final String value;
  final String? subtitle;
  final Color valueColor;
  final double valueFontSize;

  const _KpiCellData({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor = AppColors.textPrimary,
    this.valueFontSize = AppDimensions.financeStatsKpiSecondaryValueFontSize,
  });
}

class _FinanceStatsKpiCell extends StatelessWidget {
  final _KpiCellData data;

  const _FinanceStatsKpiCell({required this.data});

  @override
  Widget build(BuildContext context) {
    final semanticValue = data.subtitle == null
        ? '${data.label} ${data.value}'
        : '${data.label} ${data.value} ${data.subtitle}';

    return Semantics(
      container: true,
      label: semanticValue,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              data.value,
              style: AppTextStyles.totalAmountLora.copyWith(
                color: data.valueColor,
                fontSize: data.valueFontSize,
              ),
            ),
            if (data.subtitle != null) ...[
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                data.subtitle!,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
