import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_rows.dart';

/// L'en-tête sombre du bulletin : l'école à gauche, le titre et le mois à
/// droite — le titre passe sous l'école sur un téléphone —, puis le filet or.
class PayrollPayslipHeader extends StatelessWidget {
  final PayrollPayslipContent content;

  const PayrollPayslipHeader({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final address = content.schoolAddress;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bleuProfond,
        border: Border(
          bottom: BorderSide(
            color: AppColors.orDoux,
            width: AppDimensions.payrollPayslipRule,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content.schoolName,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.payrollAgentOnBanner,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (address != null && address.isNotEmpty)
                  Text(
                    address,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.payrollAgentOnBannerMuted,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content.title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.payrollAgentOnBanner,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Sur le bleu profond, l'or se lit : il garde sa teinte.
                Text(
                  content.monthLabel,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.orDoux,
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

/// La bande « Provisoire » sous l'en-tête, pleine largeur.
class PayrollPayslipProvisional extends StatelessWidget {
  final String text;

  const PayrollPayslipProvisional(this.text, {super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: PayrollTone.submitted.soft,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelMedium.copyWith(
          color: PayrollTone.submitted.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    ),
  );
}

/// L'identité de l'agent : trois champs par rangée, deux sur un téléphone.
class PayrollPayslipIdentity extends StatelessWidget {
  final List<PayslipRow> rows;

  const PayrollPayslipIdentity({super.key, required this.rows});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final perRow =
          constraints.maxWidth >=
              AppBreakpoints.payrollPayslipIdentityThreeColMin
          ? 3
          : 2;
      final width =
          (constraints.maxWidth - AppSpacing.md * (perRow - 1)) / perRow;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final row in rows)
            SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMutedAa,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    row.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

/// Une ligne de montant du bulletin, filet dessous. [strong] l'écrit en
/// gras ; [total] aussi, filet appuyé dessus ; une retenue nulle (« — ») passe en sourdine.
class PayrollPayslipLine extends StatelessWidget {
  final PayslipRow row;
  final Color? ink;
  final bool strong;
  final bool total;

  const PayrollPayslipLine(
    this.row, {
    super.key,
    this.ink,
    bool strong = false,
    this.total = false,
  }) : strong = strong || total;

  @override
  Widget build(BuildContext context) {
    final empty = row.value == PayrollPayslipRows.none;
    final label = (strong ? AppTypography.titleSmall : AppTypography.bodyLarge)
        .copyWith(
          color: empty ? AppColors.textMutedAa : AppColors.textPrimary,
          fontWeight: strong ? FontWeight.w700 : null,
        );
    final value = (strong ? AppTypography.titleLarge : AppTypography.labelLarge)
        .copyWith(
          color: empty ? AppColors.textMutedAa : ink ?? AppColors.textPrimary,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final note = row.note;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: total
            ? const Border(
                top: BorderSide(color: AppColors.borderStrong, width: 1.5),
              )
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label, style: label),
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
          const SizedBox(width: AppSpacing.md),
          Text(row.value, textAlign: TextAlign.end, style: value),
        ],
      ),
    );
  }
}

/// « RETENUES ……… MONTANT » : l'en-tête de colonne des retenues.
class PayrollPayslipColumns extends StatelessWidget {
  final String label;
  final String amount;

  const PayrollPayslipColumns({
    super.key,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelSmall.copyWith(
      color: AppColors.textMutedAa,
      letterSpacing: 0.6,
    );
    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label.toUpperCase(), style: style)),
          Text(amount.toUpperCase(), style: style),
        ],
      ),
    );
  }
}
