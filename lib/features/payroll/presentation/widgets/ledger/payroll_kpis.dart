import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre indicateurs du livre — masse brute, compléments, avances
/// déduites, net à payer —, une ligne par devise, jamais une somme. Puis le
/// signal du Pointage : affiché, jamais retenu.
class PayrollKpis extends StatelessWidget {
  final PayrollMonthView view;

  const PayrollKpis({super.key, required this.view});

  static List<String> _perCurrency(
    List<PayrollLine> lines,
    int Function(PayrollLine line) amountOf,
  ) => PayrollLabels.perCurrency(
    lines.map((line) => (amountOf(line), line.currency)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = view.lines;
    final installments = lines.fold<int>(
      0,
      (sum, line) =>
          sum + line.advances.where((a) => a.takenInCents > 0).length,
    );
    final locked = view.phase.isLocked;
    final absences = lines.fold<int>(
      0,
      (sum, line) => sum + line.attendance.unjustifiedAbsences,
    );
    final lates = lines.fold<int>(
      0,
      (sum, line) => sum + line.attendance.lates,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloKpiBand(
          cards: [
            EteeloKpiCardData(
              label: l10n.payrollKpiGross,
              valueLines: _perCurrency(lines, (l) => l.grossInCents),
              accent: AppColors.bleuArdoise,
              accentSoft: AppColors.bleuArdoiseSoft,
              icon: Icons.account_balance_wallet_outlined,
              subline: l10n.payrollKpiAgents(lines.length),
            ),
            EteeloKpiCardData(
              label: l10n.payrollKpiComplements,
              valueLines: _perCurrency(lines, (l) => l.complementsInCents),
              accent: AppColors.staffAttendancePresentInk,
              accentSoft: AppColors.staffAttendancePresentSoft,
              icon: Icons.add_circle_outline,
              subline: l10n.payrollKpiComplementsDetail,
            ),
            EteeloKpiCardData(
              label: l10n.payrollKpiAdvances,
              valueLines: _perCurrency(lines, (l) => l.advanceInCents),
              accent: AppColors.staffAttendanceAbsentInk,
              accentSoft: AppColors.staffAttendanceAbsentSoft,
              icon: Icons.remove_circle_outline,
              subline: l10n.payrollKpiAdvancesDetail(installments),
            ),
            EteeloKpiCardData(
              label: l10n.payrollKpiNet,
              valueLines: _perCurrency(lines, (l) => l.netInCents),
              accent: AppColors.staffAttendanceOnBanner,
              accentSoft: AppColors.staffAttendanceBannerMid,
              icon: Icons.payments_outlined,
              filledBackground: AppColors.staffAttendanceBannerStart,
              filledSecondaryInk: AppColors.staffAttendanceOnBannerMuted,
              subline: locked
                  ? l10n.payrollKpiPaid(view.paidCount, view.payable.length)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(
              Icons.fact_check_outlined,
              size: AppSpacing.lg,
              color: AppColors.textMutedAa,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.payrollAttendanceSignal(
                  PayrollLabels.month(
                    context,
                    PayrollMonth.previous(view.month),
                  ),
                  absences,
                  lates,
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
