import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_balance.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La feuille du bulletin, à l'écran : l'en-tête sombre de l'école, la
/// bande « Provisoire », l'identité, le brut (A), les retenues (B), le net
/// dû, le solde de l'agent, le pointage, puis les signatures.
class PayrollPayslipSheet extends StatelessWidget {
  final PayrollPayslipContent content;

  const PayrollPayslipSheet({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final banner = content.banner;
    final deductions = content.deductions;
    // Le brut porte seul la note du salaire de base quand rien ne s'y
    // ajoute ; sinon chaque gain est listé au-dessus de lui.
    final gross = content.gains.length == 1
        ? (
            label: content.gross.label,
            value: content.gross.value,
            note: content.gains.single.note,
          )
        : content.gross;
    return Container(
      constraints: const BoxConstraints(
        maxWidth: AppDimensions.payrollPayslipMaxWidth,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PayrollPayslipHeader(content: content),
            if (banner != null) PayrollPayslipProvisional(banner),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PayrollPayslipIdentity(rows: content.identity),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: AppSpacing.md),
                  if (content.gains.length > 1)
                    for (final row in content.gains) PayrollPayslipLine(row),
                  PayrollPayslipLine(
                    gross,
                    strong: true,
                    total: content.gains.length > 1,
                  ),
                  if (deductions.isNotEmpty) ...[
                    PayrollPayslipColumns(
                      label: l10n.payrollPayslipDeductions,
                      amount: l10n.payrollPayslipAmount,
                    ),
                    for (final row in deductions.take(deductions.length - 1))
                      PayrollPayslipLine(row, ink: PayrollTone.alert.ink),
                    PayrollPayslipLine(
                      deductions.last,
                      ink: PayrollTone.alert.ink,
                      total: true,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _NetDue(content: content),
                  const SizedBox(height: AppSpacing.md),
                  PayrollPayslipBalanceCard(balance: content.balance),
                  if (content.payment case final payment?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(payment, style: AppTypography.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _Attendance(text: content.attendance),
                  const SizedBox(height: AppSpacing.xxl),
                  _Signatures(labels: content.signatures),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Rémunération due (net à payer) · (A) − (B) » sur un voile chaud, et
/// la mention légale dessous quand rien de légal n'est retenu.
class _NetDue extends StatelessWidget {
  final PayrollPayslipContent content;

  const _NetDue({required this.content});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                content.net.label,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              content.net.value,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.bleuProfond,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
      if (content.legalNote case final note?)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            note,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
        ),
    ],
  );
}

/// Le pointage du mois, ⓘ en tête.
class _Attendance extends StatelessWidget {
  final String text;

  const _Attendance({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: AppRadius.brMd,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: AppSpacing.lg,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTypography.bodySmall)),
      ],
    ),
  );
}

/// Les trois signatures du modèle papier : un trait, l'intitulé dessous.
class _Signatures extends StatelessWidget {
  final List<String> labels;

  const _Signatures({required this.labels});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (index, label) in labels.indexed) ...[
        if (index > 0) const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            children: [
              const Divider(color: AppColors.borderStrong),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}
