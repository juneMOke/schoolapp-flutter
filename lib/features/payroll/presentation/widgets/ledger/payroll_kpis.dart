import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_kpi_card.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_attendance_rule.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre indicateurs du livre — masse brute, compléments, avances
/// déduites, net à payer —, une ligne par devise, jamais une somme. Puis le
/// signal du Pointage : retenu seulement si l'école retient les absences
/// (jours prestés, v2).
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
    final deferred = _perCurrency(lines, (l) => l.deferredInCents);
    final attendanceMonth = PayrollLabels.month(context, view.attendanceMonth);
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
            PayrollKpiCard.of(
              label: l10n.payrollKpiGross,
              valueLines: _perCurrency(lines, (l) => l.grossInCents),
              accent: DashboardSense.attendu,
              icon: Icons.account_balance_wallet_outlined,
              subline: l10n.payrollKpiAgents(lines.length),
            ),
            // Ce que l'école retient, séparé de ce que l'agent rembourse :
            // une échéance d'avance rend son propre argent.
            PayrollKpiCard.of(
              label: l10n.payrollKpiSchoolDeductions,
              valueLines: _perCurrency(lines, (l) => l.deductions.totalInCents),
              accent: DashboardSense.manquant,
              icon: Icons.remove_circle_outline,
              subline: l10n.payrollKpiSchoolDeductionsDetail,
            ),
            PayrollKpiCard.of(
              label: l10n.payrollKpiLoans,
              valueLines: _perCurrency(lines, (l) => l.advanceInCents),
              accent: DashboardSense.attente,
              icon: Icons.handshake_outlined,
              subline: l10n.payrollKpiAdvancesDetail(installments),
            ),
            PayrollKpiCard.of(
              label: l10n.payrollKpiNet,
              valueLines: _perCurrency(lines, (l) => l.netInCents),
              // Un décaissement, comme au tableau de bord : rien n'est
              // « encaissé » sur un brouillon.
              accent: DashboardSense.marque,
              icon: Icons.payments_outlined,
              subline: locked
                  ? l10n.payrollKpiPaid(view.paidCount, view.payable.length)
                  : view.hasReducedPayout
                  ? l10n.payrollKpiNetToPay(
                      _perCurrency(lines, (l) => l.toPayInCents).join(' · '),
                      deferred.join(' · '),
                    )
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
                view.attendance == PayrollAttendanceState.open
                    ? l10n.payrollAttendanceSignalOpen(attendanceMonth)
                    : (view.absenceDeductionEnabled
                          ? l10n.payrollAttendanceSignalDeducted
                          : l10n.payrollAttendanceSignal)(
                        attendanceMonth,
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
