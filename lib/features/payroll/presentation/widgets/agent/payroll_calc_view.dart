import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_calc_payout.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le détail du calcul d'un mois : chaque montant avec sa formule, pour
/// répondre à « pourquoi ce net ? » sans ouvrir le tableur.
///
/// Les lignes sont **celles du bulletin** ([PayrollPayslipContent]) : le
/// calcul à l'écran et le bulletin ne peuvent pas diverger. Seule l'absence
/// gagne ici sa formule (jours × base ÷ diviseur).
class PayrollCalcView extends StatelessWidget {
  final PayrollPayslipContent content;
  final PayrollAgentMonth month;

  const PayrollCalcView({
    super.key,
    required this.content,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final line = month.line;
    final deductions = content.deductions;
    final total = deductions.isEmpty ? null : deductions.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(number: 1, title: l10n.payrollCalcGains),
        for (final row in content.gains)
          _CalcRow(
            sign: '+',
            label: row.label,
            note: row.note,
            value: row.value,
          ),
        _CalcRow.total(
          label: l10n.payrollCalcGross,
          value: content.gross.value,
        ),
        _Section(number: 2, title: l10n.payrollCalcDeductions),
        for (final row in deductions.take(deductions.length - 1))
          _CalcRow(
            sign: '−',
            label: row.label,
            note: row.label == l10n.payrollPayslipAbsence
                ? _absenceNote(context) ?? row.note
                : row.note,
            value: row.value,
            ink: PayrollTone.alert.ink,
          ),
        if (total != null)
          _CalcRow.total(
            label: l10n.payrollCalcDeductionsTotal,
            value: total.value,
            ink: PayrollTone.alert.ink,
          ),
        _Section(number: 3, title: l10n.payrollCalcNet),
        _CalcRow.total(
          label: l10n.payrollCalcNetToPay,
          value: content.net.value,
          ink: AppColors.bleuProfond,
        ),
        if (line.netInCents > 0) ...[
          _Section(number: 4, title: l10n.payrollCalcPayout),
          PayrollCalcPayout(month: month),
        ],
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: AppRadius.brMd,
          ),
          child: Text(content.attendance, style: AppTypography.bodySmall),
        ),
      ],
    );
  }

  /// « 1 j non presté × 13,46 $ / j (base ÷ 26 j) » — ou pourquoi rien
  /// n'est retenu.
  String? _absenceNote(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final line = month.line;
    final d = line.deductions;
    final divisor = d.workDaysDivisor;
    if (line.isHourly || divisor == null) return l10n.payrollCalcAbsenceHourly;
    final days = d.absentDays ?? 0;
    if (days <= 0) return null;
    if (d.absenceInCents <= 0) return l10n.payrollCalcAbsenceIndicative(days);
    return l10n.payrollCalcAbsenceFormula(
      days,
      PayrollLabels.money(line.baseInCents ~/ divisor, line.currency),
      divisor,
    );
  }
}

/// « 1 Gains » : le numéro en pastille, puis le titre.
class _Section extends StatelessWidget {
  final int number;
  final String title;

  const _Section({required this.number, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
    child: Row(
      children: [
        CircleAvatar(
          radius: AppSpacing.md - AppSpacing.xs / 2,
          backgroundColor: PayrollTone.current.soft,
          child: Text(
            '$number',
            style: AppTypography.labelMedium.copyWith(
              color: PayrollTone.current.ink,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title.toUpperCase(), style: AppTypography.labelLarge),
      ],
    ),
  );
}

/// Signe · libellé et formule · montant. Une ligne nulle (« — ») reste
/// listée, en sourdine : les cinq retenues du modèle papier sont toujours là.
class _CalcRow extends StatelessWidget {
  final String sign;
  final String label;
  final String? note;
  final String value;
  final Color? ink;
  final bool strong;

  const _CalcRow({
    required this.sign,
    required this.label,
    required this.value,
    this.note,
    this.ink,
  }) : strong = false;

  const _CalcRow.total({required this.label, required this.value, this.ink})
    : sign = '=',
      note = null,
      strong = true;

  @override
  Widget build(BuildContext context) {
    final empty = value == '—';
    final color = empty ? AppColors.textMutedAa : null;
    final figures = AppTypography.labelLarge.copyWith(
      color: empty ? AppColors.textMutedAa : ink,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final note = this.note;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: strong
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderStrong, width: 1.5),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.lg,
            child: Text(
              sign,
              textAlign: TextAlign.center,
              style: figures.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      (strong
                              ? AppTypography.titleSmall
                              : AppTypography.bodyMedium)
                          .copyWith(color: color),
                ),
                if (note != null)
                  Text(
                    note,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(value, textAlign: TextAlign.end, style: figures),
        ],
      ),
    );
  }
}
