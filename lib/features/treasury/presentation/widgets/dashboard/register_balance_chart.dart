import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/theme/currency_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/selectable_balance_line.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/treasury_balance_line.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
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

  /// Toucher un point ouvre le rapport de sa tranche (R7).
  final ValueChanged<EvolutionPoint>? onOpenPoint;

  const RegisterBalanceChart({
    super.key,
    required this.series,
    required this.granularity,
    required this.period,
    this.onOpenPoint,
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
    final screen = MediaQuery.sizeOf(context);
    final compact = screen.width < AppBreakpoints.treasuryChartCompactMax;
    // La hauteur aussi : en paysage, un téléphone est large mais bas.
    final low = screen.height < AppBreakpoints.treasuryChartLowHeightMax;
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
          borderRadius: BorderRadius.circular(
            AppDimensions.treasuryPanelRadius,
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: TreasuryTones.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.treasuryRegisterCardPadV),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                series: series,
                subtitle: l10n.treasuryChartBalance(
                  granularityLabel(l10n, granularity),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _BalanceBand(
                currency: currency,
                closingInCents: s.closingInCents,
                variation: variation,
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
                SelectableBalanceLine(
                  height: low
                      ? AppDimensions.treasuryChartHeightLow
                      : compact
                      ? AppDimensions.treasuryChartHeightCompact
                      : AppDimensions.treasuryChartHeight,
                  currency: currency,
                  openingInCents: s.openingInCents,
                  lineColor: accent,
                  onOpenSlot: onOpenPoint == null
                      ? null
                      : (index) => onOpenPoint!(series.points[index]),
                  slots: [
                    for (final (index, p) in series.points.indexed)
                      BalanceSlot(
                        label: bucketLabel(l10n, granularity, period, p, index),
                        balanceInCents: p.balanceInCents,
                        inflowsInCents: p.inflowsInCents,
                        outflowsInCents: p.outflowsInCents,
                        partial: p.partial,
                      ),
                  ],
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
      // Une période libre en semaines se date (« 5 oct. ») ; un mois les
      // numérote (S1 … Sn).
      EvolutionGranularity.week =>
        period == EvolutionPeriod.custom
            ? l10n.treasuryShortDateBucket(start)
            : l10n.treasuryWeekBucket(index + 1),
      EvolutionGranularity.month => l10n.treasuryMonthBucket(start),
    };
  }
}

class _Header extends StatelessWidget {
  final RegisterSeries series;
  final String subtitle;

  const _Header({required this.series, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = series.register;
    final currency = register.currency;
    final s = series.synthesis;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDimensions.treasuryIconBox,
              height: AppDimensions.treasuryIconBox,
              decoration: BoxDecoration(
                gradient: TreasuryTones.gradient(currency),
                borderRadius: BorderRadius.circular(
                  AppDimensions.treasuryIconBoxRadius,
                ),
              ),
              child: const Icon(
                Icons.payments_outlined,
                size: AppSpacing.lg + 2,
                color: AppColors.surfaceRaised,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(register.name, style: AppTypography.titleSmall),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: [
            _Figure(
              icon: Icons.calendar_today_outlined,
              label: l10n.treasuryOpening,
              value: TreasuryFormat.money(s.openingInCents, currency),
              tone: TreasuryTones.opening,
            ),
            _Figure(
              icon: Icons.download_outlined,
              label: l10n.treasuryInflows,
              value: TreasuryFormat.signedMoney(s.inflowsInCents, currency),
              tone: TreasuryTones.inflow,
            ),
            _Figure(
              icon: Icons.upload_outlined,
              label: l10n.treasuryOutflows,
              value: TreasuryFormat.signedMoney(-s.outflowsInCents, currency),
              tone: TreasuryTones.outflow,
            ),
            // R17 : sans les écarts, ouverture + entrées − sorties ne
            // tomberait pas sur le solde.
            if (s.gapsInCents != 0)
              _Figure(
                icon: Icons.error_outline,
                label: l10n.treasuryChartGaps,
                value: TreasuryFormat.signedMoney(s.gapsInCents, currency),
                tone: TreasuryTones.outflow,
              ),
          ],
        ),
      ],
    );
  }
}

/// Une pastille chiffrée : icône et libellé en capitales, montant exact.
class _Figure extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TreasuryTone tone;

  const _Figure({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.treasuryFigurePadH,
      vertical: AppDimensions.treasuryFigurePadV,
    ),
    decoration: BoxDecoration(
      color: tone.soft,
      border: Border.all(color: tone.border),
      borderRadius: BorderRadius.circular(AppDimensions.treasuryFigureRadius),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.md - 1, color: tone.ink),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label.toUpperCase(),
              style: AppTypography.labelCaps.copyWith(color: tone.ink),
            ),
          ],
        ),
        Text(
          value,
          softWrap: false,
          style: AppTextStyles.moneyTabular.copyWith(
            color: tone.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// Le solde de la plage, sur toute la largeur, au ton de la devise, et sa
/// variation (entrées − sorties) / ouverture ; « — » si l'ouverture vaut 0.
class _BalanceBand extends StatelessWidget {
  final TreasuryCurrency currency;
  final int closingInCents;
  final int? variation;

  const _BalanceBand({
    required this.currency,
    required this.closingInCents,
    required this.variation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = TreasuryTones.currency(currency);
    final variation = this.variation;
    final trend = variation == null
        ? '—'
        : '${variation > 0
              ? '▲ +'
              : variation < 0
              ? '▼ '
              : ''}$variation %';
    final trendInk = variation == null || variation == 0
        ? AppColors.textSecondary
        : variation > 0
        ? TreasuryTones.inflow.ink
        : TreasuryTones.outflow.ink;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.treasuryFigurePadH,
        vertical: AppDimensions.treasuryFigurePadV,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        border: Border.all(color: tone.border),
        borderRadius: BorderRadius.circular(AppDimensions.treasuryFigureRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            l10n.treasuryChartBalanceLabel.toUpperCase(),
            style: AppTypography.labelCaps.copyWith(color: tone.ink),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: TreasuryFormat.money(closingInCents, currency),
                    style: AppTextStyles.moneyTabular.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: AppDimensions.treasuryPeriodTotalSize - 3,
                    ),
                  ),
                  TextSpan(
                    text: '  $trend',
                    style: AppTypography.labelSmall.copyWith(
                      color: trendInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
