import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_month_actions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_calc_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_settlement_pill.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_status_pill.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum _View { calc, payslip }

/// Le panneau du mois choisi : son statut et ses gestes, puis le détail du
/// calcul ou le bulletin — le choix tient d'un mois à l'autre — et le
/// barème appliqué en pied.
class PayrollAgentMonthPanel extends StatefulWidget {
  final PayrollSnapshot snapshot;
  final PayrollAgentMonth month;

  const PayrollAgentMonthPanel({
    super.key,
    required this.snapshot,
    required this.month,
  });

  @override
  State<PayrollAgentMonthPanel> createState() => _PayrollAgentMonthPanelState();
}

class _PayrollAgentMonthPanelState extends State<PayrollAgentMonthPanel> {
  _View _view = _View.calc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final month = widget.month;
    final label = PayrollLabels.month(context, month.month);
    final content = PayrollPayslipContent.of(
      context,
      snapshot: widget.snapshot,
      view: month.view,
      line: month.line,
    );
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.payrollAgentPanelEyebrow.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMutedAa,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          label[0].toUpperCase() + label.substring(1),
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.bleuProfond,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            PayrollStatusPill(phase: month.phase),
            if (month.isFrozen && !month.isLegacy)
              PayrollSettlementPill(status: month.settlement.status),
          ],
        ),
      ],
    );
    final scale = _scale(context);
    return EteeloPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              heading,
              PayrollAgentMonthActions(month: month, snapshot: widget.snapshot),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedTabFilter<_View>(
            options: [
              SegmentedTabOption(
                label: l10n.payrollAgentSegmentCalc,
                value: _View.calc,
                icon: Icons.calculate_outlined,
              ),
              SegmentedTabOption(
                label: l10n.payrollAgentSegmentPayslip,
                value: _View.payslip,
                icon: Icons.description_outlined,
              ),
            ],
            selected: _view,
            onSelected: (view) => setState(() => _view = view),
          ),
          const SizedBox(height: AppSpacing.md),
          switch (_view) {
            _View.calc => PayrollCalcView(content: content, month: month),
            _View.payslip => Center(
              child: PayrollPayslipSheet(content: content),
            ),
          },
          if (scale != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              scale,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// « Barème figé à la validation : 26 j de référence · absences
  /// retenues. » — rien pour un vacataire à l'heure.
  String? _scale(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final month = widget.month;
    final days = month.line.deductions.workDaysDivisor;
    if (days == null) return null;
    // Une ligne figée dit elle-même si l'absence a été retenue ; le réglage
    // de l'école a pu changer depuis la validation.
    final d = month.line.deductions;
    final deducted = month.line.frozen && (d.absentDays ?? 0) > 0
        ? d.absenceInCents > 0
        : month.view.absenceDeductionEnabled;
    final absences = deducted
        ? l10n.payrollAgentAbsencesDeducted
        : l10n.payrollAgentAbsencesIndicative;
    return month.line.frozen
        ? l10n.payrollAgentScaleFrozen(days, absences)
        : l10n.payrollAgentScaleCurrent(days, absences);
  }
}
