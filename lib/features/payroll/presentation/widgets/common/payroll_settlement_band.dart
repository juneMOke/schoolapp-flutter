import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settlement.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le solde progressif d'un salaire : net du mois, déjà versé, reste à
/// payer, et la barre de ce qui est réglé.
class PayrollSettlementBand extends StatelessWidget {
  final PayrollSettlement settlement;

  const PayrollSettlementBand({super.key, required this.settlement});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = settlement.line.currency;
    String money(int cents) => PayrollLabels.money(cents, currency);
    final net = settlement.netInCents;
    final ratio = net <= 0
        ? 1.0
        : (settlement.paidInCents / net).clamp(0.0, 1.0).toDouble();
    Widget cell(String label, String value, {Color? ink}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: ink ?? AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cell(l10n.payrollSettleNet, money(net)),
            const SizedBox(width: AppSpacing.sm),
            cell(
              l10n.payrollSettlePaid,
              money(settlement.paidInCents),
              ink: PayrollTone.paid.ink,
            ),
            const SizedBox(width: AppSpacing.sm),
            cell(
              l10n.payrollSettleRemaining,
              money(settlement.remainingInCents),
              ink: settlement.remainingInCents > 0
                  ? PayrollTone.submitted.ink
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.brMd,
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: AppSpacing.sm,
            color: PayrollTone.paid.color,
            backgroundColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}
