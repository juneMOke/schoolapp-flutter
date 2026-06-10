import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne de frais de l'élève (spec §11).
///
/// En-tête (libellé + badge de statut), barre de progression et pied
/// « Attendu · Payé · {reste} restant ». La ligne reste cliquable.
class FacturationChargeLine extends StatelessWidget {
  final StudentCharge charge;
  final VoidCallback onViewRequested;

  const FacturationChargeLine({
    super.key,
    required this.charge,
    required this.onViewRequested,
  });

  String _formatAmount(double cents) => formatMonetaryAmountWithCurrency(
    amount: cents / 100,
    currency: charge.currency,
  );

  double get _progress {
    if (charge.expectedAmountInCents <= 0) {
      return charge.amountPaidInCents > 0 ? 1 : 0;
    }
    return (charge.amountPaidInCents / charge.expectedAmountInCents).clamp(
      0.0,
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = charge.status;
    final visuals = status.visuals;
    final remaining = charge.expectedAmountInCents - charge.amountPaidInCents;
    final isSettled = remaining <= 0;

    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onViewRequested,
        borderRadius: AppRadius.brMd,
        hoverColor: AppColors.bleuArdoise.withValues(alpha: 0.06),
        splashColor: AppColors.bleuArdoise.withValues(alpha: 0.10),
        highlightColor: AppColors.bleuArdoise.withValues(alpha: 0.12),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                label: charge.feeCode.localizedFeeLabel(l10n),
                statusLabel: status.localizedLabel(l10n),
                visuals: visuals,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _ProgressBar(progress: _progress, fill: visuals.color),
              const SizedBox(height: AppDimensions.spacingS),
              _Footer(
                expectedLabel: l10n.facturationDetailChargeExpectedAmountColumn,
                paidLabel: l10n.facturationDetailChargePaidAmountColumn,
                expected: _formatAmount(charge.expectedAmountInCents),
                paid: _formatAmount(charge.amountPaidInCents),
                remainingText: isSettled
                    ? null
                    : l10n.facturationChargeLineRemainingSuffix(
                        _formatAmount(remaining),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String label;
  final String statusLabel;
  final FeeStatusVisuals visuals;

  const _Header({
    required this.label,
    required this.statusLabel,
    required this.visuals,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        _StatusBadge(statusLabel: statusLabel, visuals: visuals),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String statusLabel;
  final FeeStatusVisuals visuals;

  const _StatusBadge({required this.statusLabel, required this.visuals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: visuals.soft,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: visuals.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visuals.icon, size: 14, color: visuals.color),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            statusLabel,
            style: AppTextStyles.badge.copyWith(color: visuals.color),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color fill;

  const _ProgressBar({required this.progress, required this.fill});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brPill,
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 7,
        backgroundColor: AppColors.surfaceAlt,
        valueColor: AlwaysStoppedAnimation<Color>(fill),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final String expectedLabel;
  final String paidLabel;
  final String expected;
  final String paid;
  final String? remainingText;

  const _Footer({
    required this.expectedLabel,
    required this.paidLabel,
    required this.expected,
    required this.paid,
    required this.remainingText,
  });

  @override
  Widget build(BuildContext context) {
    final mutedStyle = AppTextStyles.caption.copyWith(
      color: AppColors.textMuted,
    );
    final strongStyle = AppTextStyles.caption.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );

    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingXS,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$expectedLabel ', style: mutedStyle),
              TextSpan(text: expected, style: strongStyle),
            ],
          ),
        ),
        Text('·', style: mutedStyle),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$paidLabel ', style: mutedStyle),
              TextSpan(text: paid, style: strongStyle),
            ],
          ),
        ),
        if (remainingText != null) ...[
          Text('·', style: mutedStyle),
          Text(
            remainingText!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.feeStatusDue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
