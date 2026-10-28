import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_tile.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
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
      KubaBannerTile(
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
      KubaBannerTile(
        label: l10n.payrollAgentLoans,
        values: loans.isEmpty ? [l10n.payrollNoValue] : loans,
        detail: loans.isEmpty
            ? l10n.payrollAgentLoansNone
            : l10n.payrollAgentLoansHint,
      ),
      KubaBannerTile(
        label: l10n.payrollAgentPaidYear(situation.year),
        values: paid.isEmpty ? [l10n.payrollNoValue] : paid,
        detail: totals.isEmpty
            ? l10n.payrollAgentPaidYearNone
            : l10n.payrollAgentPaidYearOf(months, due.join(' · ')),
      ),
      if (upcoming != null)
        KubaBannerTile(
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
