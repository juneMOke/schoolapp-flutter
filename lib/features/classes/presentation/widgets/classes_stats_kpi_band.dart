import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesStatsKpiBand extends StatelessWidget {
  final ClassroomStats stats;

  const ClassesStatsKpiBand({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalStudents = stats.kpis.totalActive + stats.kpis.inactive;
    final activeTotal = stats.kpis.totalActive;
    final girlsPercent = _safePercent(stats.kpis.activeGirls, activeTotal);
    final boysPercent = _safePercent(stats.kpis.activeBoys, activeTotal);

    return Semantics(
      container: true,
      label: l10n.classesStatsKpiBandA11yLabel,
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
            final isCompact = constraints.maxWidth < 860;
            if (isCompact) {
              return Wrap(
                spacing: AppDimensions.spacingM,
                runSpacing: AppDimensions.spacingM,
                children: [
                  _KpiPrimaryCell(
                    label: l10n.classesStatsKpiTotalStudents,
                    value: totalStudents,
                  ),
                  _KpiDonutCell(
                    label: l10n.classesStatsKpiActiveGirls,
                    value: stats.kpis.activeGirls,
                    percent: girlsPercent,
                    color: AppColors.bleuArdoise,
                  ),
                  _KpiDonutCell(
                    label: l10n.classesStatsKpiActiveBoys,
                    value: stats.kpis.activeBoys,
                    percent: boysPercent,
                    color: AppColors.orDoux,
                  ),
                  _KpiSecondaryCell(
                    label: l10n.classesStatsKpiInactiveStudents,
                    value: stats.kpis.inactive,
                    valueColor: AppColors.warning,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _KpiPrimaryCell(
                    label: l10n.classesStatsKpiTotalStudents,
                    value: totalStudents,
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _KpiDonutCell(
                    label: l10n.classesStatsKpiActiveGirls,
                    value: stats.kpis.activeGirls,
                    percent: girlsPercent,
                    color: AppColors.bleuArdoise,
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _KpiDonutCell(
                    label: l10n.classesStatsKpiActiveBoys,
                    value: stats.kpis.activeBoys,
                    percent: boysPercent,
                    color: AppColors.orDoux,
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _KpiSecondaryCell(
                    label: l10n.classesStatsKpiInactiveStudents,
                    value: stats.kpis.inactive,
                    valueColor: AppColors.warning,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _safePercent(int value, int total) {
    if (total <= 0) return 0;
    return ((value * 100) / total).round();
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: AppDimensions.financeStatsKpiDividerHeight,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
      color: AppColors.border,
    );
  }
}

class _KpiPrimaryCell extends StatelessWidget {
  final String label;
  final int value;

  const _KpiPrimaryCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label $value',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              '$value',
              style: AppTextStyles.totalAmountLora.copyWith(
                color: AppColors.bleuProfond,
                fontSize: AppDimensions.financeStatsKpiPrimaryValueFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiSecondaryCell extends StatelessWidget {
  final String label;
  final int value;
  final Color valueColor;

  const _KpiSecondaryCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label $value',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              '$value',
              style: AppTextStyles.totalAmountLora.copyWith(
                color: valueColor,
                fontSize: AppDimensions.financeStatsKpiSecondaryValueFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiDonutCell extends StatelessWidget {
  final String label;
  final int value;
  final int percent;
  final Color color;

  const _KpiDonutCell({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label $value $percent%',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Row(
              children: [
                _CompactDonut(percent: percent, color: color),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '$value',
                  style: AppTextStyles.totalAmountLora.copyWith(
                    color: AppColors.textPrimary,
                    fontSize:
                        AppDimensions.financeStatsKpiSecondaryValueFontSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactDonut extends StatelessWidget {
  final int percent;
  final Color color;

  const _CompactDonut({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.textMuted.withValues(alpha: 0.25),
            ),
          ),
          CircularProgressIndicator(
            value: percent.clamp(0, 100) / 100,
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$percent%',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
