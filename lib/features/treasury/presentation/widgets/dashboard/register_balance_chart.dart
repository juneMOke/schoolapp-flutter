import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/evolution_line_chart.dart';
import 'package:school_app_flutter/core/components/charts/line_chart_point.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/theme/currency_tones.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La courbe du solde d'une caisse sur la période (A4) : l'en-tête chiffré
/// en montants exacts (ouverture, entrées, sorties, solde et sa variation,
/// écarts s'il y en a), puis le solde tranche par tranche, l'ouverture en
/// ligne de repère. Les tranches à venir n'ont pas de point.
class RegisterBalanceChart extends StatelessWidget {
  final RegisterSeries series;
  final EvolutionGranularity granularity;

  /// « Cette semaine » nomme ses jours (lun., mar.) ; une période libre les
  /// date (12 oct.).
  final EvolutionPeriod period;

  const RegisterBalanceChart({
    super.key,
    required this.series,
    required this.granularity,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = series.register;
    final currency = register.currency;
    final s = series.synthesis;
    final accent = CurrencyTones.accent(currency.code);
    final known = [
      for (final (index, p) in series.points.indexed)
        if (p.balanceInCents != null) (index, p),
    ];
    final compact =
        MediaQuery.sizeOf(context).width <
        AppBreakpoints.treasuryChartCompactMax;
    final variation = s.variationPercent;
    return Semantics(
      label: l10n.treasuryChartSemantics(
        register.name,
        TreasuryFormat.money(s.openingInCents, currency),
        TreasuryFormat.money(s.closingInCents, currency),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.border),
          boxShadow: DashboardTones.paveShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(register.name, style: AppTypography.titleSmall),
                      Text(
                        l10n.treasuryChartBalance(
                          granularityLabel(l10n, granularity),
                        ),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  _Figure(
                    label: l10n.treasuryOpening,
                    value: TreasuryFormat.money(s.openingInCents, currency),
                    ink: AppColors.terreCuite,
                  ),
                  _Figure(
                    label: l10n.treasuryInflows,
                    value: TreasuryFormat.signedMoney(
                      s.inflowsInCents,
                      currency,
                    ),
                    ink: AppColors.success,
                  ),
                  _Figure(
                    label: l10n.treasuryOutflows,
                    value: TreasuryFormat.signedMoney(
                      -s.outflowsInCents,
                      currency,
                    ),
                    ink: AppColors.error,
                  ),
                  _Figure(
                    label: l10n.treasuryChartBalanceLabel,
                    value:
                        '${TreasuryFormat.money(s.closingInCents, currency)}'
                        // « — » quand l'ouverture vaut 0 (R2).
                        ' ${variation == null ? '—' : '${variation > 0
                                  ? '▲ +'
                                  : variation < 0
                                  ? '▼ '
                                  : ''}$variation %'}',
                    ink: accent,
                  ),
                  // R17 : sans les écarts, ouverture + entrées − sorties ne
                  // tomberait pas sur le solde.
                  if (s.gapsInCents != 0)
                    _Figure(
                      label: l10n.treasuryChartGaps,
                      value: TreasuryFormat.signedMoney(
                        s.gapsInCents,
                        currency,
                      ),
                      ink: AppColors.error,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (known.isEmpty)
                Text(
                  l10n.treasuryChartNoPoint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                SizedBox(
                  height: compact
                      ? AppDimensions.treasuryChartHeightCompact
                      : AppDimensions.treasuryChartHeight,
                  child: EvolutionLineChart(
                    points: [
                      for (final (i, (index, p)) in known.indexed)
                        LineChartPoint(
                          label: bucketLabel(
                            l10n,
                            granularity,
                            period,
                            p,
                            index,
                          ),
                          value: p.balanceInCents! / 100,
                          isHighlighted: i == known.length - 1,
                        ),
                    ],
                    lineColor: accent,
                    highlightColor: AppColors.terreCuite,
                    minY: 0,
                    targetLine: s.openingInCents / 100,
                    targetLineColor: AppColors.terreCuite,
                    targetLineLabel: l10n.treasuryOpening,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String granularityLabel(
    AppLocalizations l10n,
    EvolutionGranularity granularity,
  ) => switch (granularity) {
    EvolutionGranularity.hour => l10n.treasuryGranHour,
    EvolutionGranularity.day => l10n.treasuryGranDay,
    EvolutionGranularity.week => l10n.treasuryGranWeek,
    EvolutionGranularity.month => l10n.treasuryGranMonth,
  };

  /// Le libellé d'axe d'une tranche, lu à l'heure de l'école : « 9 h »,
  /// « lun. », « S2 », « oct. ».
  static String bucketLabel(
    AppLocalizations l10n,
    EvolutionGranularity granularity,
    EvolutionPeriod period,
    EvolutionPoint point,
    int index,
  ) {
    final start = SchoolTime.wallClock(point.start);
    return switch (granularity) {
      EvolutionGranularity.hour => l10n.treasuryHourBucket(start.hour),
      EvolutionGranularity.day =>
        period == EvolutionPeriod.week
            ? l10n.treasuryDayBucket(start)
            : l10n.treasuryShortDateBucket(start),
      EvolutionGranularity.week => l10n.treasuryWeekBucket(index + 1),
      EvolutionGranularity.month => l10n.treasuryMonthBucket(start),
    };
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color ink;

  const _Figure({required this.label, required this.value, required this.ink});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs + 2,
    ),
    decoration: BoxDecoration(
      color: ink.withValues(alpha: 0.08),
      borderRadius: AppRadius.brMd,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(color: ink),
        ),
        Text(
          value,
          softWrap: false,
          style: AppTextStyles.moneyTabular.copyWith(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
