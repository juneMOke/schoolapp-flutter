import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre chiffres du bandeau : quatre en ligne en paysage, 2 × 2 en
/// portrait. Une devise par ligne de valeur.
class PayrollAgentHeroTiles extends StatelessWidget {
  final PayrollAgentSituation situation;

  const PayrollAgentHeroTiles({super.key, required this.situation});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<String> amounts(Map<String, int> byCurrency) =>
        PayrollLabels.perCurrency([
          for (final entry in byCurrency.entries) (entry.value, entry.key),
        ]);
    final owed = amounts(situation.outstanding);
    final loans = amounts(situation.loansOutstanding);
    final totals = situation.totals;
    final paid = PayrollLabels.perCurrency([
      for (final t in totals) (t.paidInCents, t.currency),
    ]);
    final due = PayrollLabels.perCurrency([
      for (final t in totals) (t.netInCents, t.currency),
    ]);
    final months = totals.fold(0, (sum, t) => sum > t.months ? sum : t.months);
    final upcoming = situation.upcoming;
    final tiles = [
      _Tile(
        label: l10n.payrollAgentOwed,
        values: owed.isEmpty
            ? [
                PayrollLabels.money(
                  0,
                  situation.months.firstOrNull?.line.currency ?? '',
                ),
              ]
            : owed,
        valueColor: owed.isEmpty
            ? AppColors.payrollAgentBannerGood
            : AppColors.orDoux,
        detail: owed.isEmpty
            ? l10n.payrollAgentOwedNone
            : l10n.payrollAgentOwedMonths(situation.unsettledMonths),
      ),
      _Tile(
        label: l10n.payrollAgentLoans,
        values: loans.isEmpty ? const ['—'] : loans,
        detail: loans.isEmpty
            ? l10n.payrollAgentLoansNone
            : l10n.payrollAgentLoansHint,
      ),
      _Tile(
        label: l10n.payrollAgentPaidYear(situation.year),
        values: paid.isEmpty ? const ['—'] : paid,
        detail: totals.isEmpty
            ? l10n.payrollAgentPaidYearNone
            : l10n.payrollAgentPaidYearOf(months, due.join(' · ')),
      ),
      if (upcoming != null)
        _Tile(
          label: l10n.payrollAgentUpcoming(
            PayrollLabels.month(context, upcoming.month),
          ),
          values: [
            PayrollLabels.money(
              upcoming.line.netInCents,
              upcoming.line.currency,
            ),
          ],
          detail: PayrollLabels.phase(l10n, upcoming.phase),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow =
            constraints.maxWidth >= AppBreakpoints.payrollAgentTilesInRowMin
            ? tiles.length
            : 2;
        final width =
            (constraints.maxWidth - AppSpacing.md * (perRow - 1)) / perRow;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width < AppDimensions.payrollAgentTileMin
                    ? constraints.maxWidth
                    : width,
                child: tile,
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final List<String> values;
  final String detail;
  final Color valueColor;

  const _Tile({
    required this.label,
    required this.values,
    required this.detail,
    this.valueColor = AppColors.payrollAgentOnBanner,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.payrollAgentOnBannerMuted,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.payrollAgentBannerTile,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.payrollAgentOnBannerFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final value in values)
            // Un montant ne se coupe jamais : il rétrécit plutôt.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.titleLarge.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ],
      ),
    );
  }
}
