import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';

/// La feuille du bulletin, à l'écran : le même contenu que le PDF.
class PayrollPayslipSheet extends StatelessWidget {
  final PayrollPayslipContent content;

  const PayrollPayslipSheet({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final banner = content.banner;
    final address = content.schoolAddress;
    return Container(
      constraints: const BoxConstraints(
        maxWidth: AppDimensions.payrollPayslipMaxWidth,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.papier,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.schoolName, style: AppTypography.titleMedium),
                    if (address != null && address.isNotEmpty)
                      Text(
                        address,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMutedAa,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    content.title,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.bleuProfond,
                    ),
                  ),
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
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: AppDimensions.payrollPayslipRule,
            color: AppColors.orDoux,
          ),
          if (banner != null) ...[
            const SizedBox(height: AppSpacing.md),
            PayrollTone.submitted.notice(banner, icon: Icons.edit_note),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              for (final row in content.identity)
                _Field(label: row.label, value: row.value),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final row in content.gains) _Amount(row),
          _Amount(content.gross, strong: true),
          if (content.deductions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final row in content.deductions)
              _Amount(row, color: PayrollTone.alert.ink),
          ],
          const Divider(height: AppSpacing.xl),
          _Amount(content.net, strong: true, large: true),
          Text(
            content.legalNote,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brMd,
            ),
            child: Text(content.attendance, style: AppTypography.bodySmall),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(content.payment, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              for (final signature in content.signatures)
                Expanded(
                  child: Column(
                    children: [
                      const Divider(),
                      Text(
                        signature,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMutedAa,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(color: AppColors.textMutedAa),
      ),
      Text(value, style: AppTypography.labelLarge),
    ],
  );
}

class _Amount extends StatelessWidget {
  final PayslipRow row;
  final bool strong;
  final bool large;
  final Color? color;

  const _Amount(
    this.row, {
    this.strong = false,
    this.large = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        (large
                ? AppTypography.titleLarge
                : strong
                ? AppTypography.labelLarge
                : AppTypography.bodyMedium)
            .copyWith(
              color: color ?? AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    final note = row.note;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label, style: style),
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
          Text(row.value, style: style),
        ],
      ),
    );
  }
}
