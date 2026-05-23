import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc de synthèse pour détail charge : nom + badge statut + 3 KPIs (Attendu/Payé/Reste).
class FacturationChargeSummaryStrip extends StatelessWidget {
  final String chargeLabel;
  final StudentChargeStatus chargeStatus;
  final double expectedAmountInCents;
  final double amountPaidInCents;
  final String currency;

  const FacturationChargeSummaryStrip({
    super.key,
    required this.chargeLabel,
    required this.chargeStatus,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    required this.currency,
  });

  double get _remainingInCents => expectedAmountInCents - amountPaidInCents;

  String _formatAmount(double cents) {
    return formatMonetaryAmountWithCurrency(
      amount: cents / 100,
      currency: currency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + Badge statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  chargeLabel,
                  style: AppTextStyles.totalAmountLora.copyWith(
                    fontSize: 20,
                    color: AppColors.bleuArdoise,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: chargeStatus.badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
                  border: Border.all(
                    color: chargeStatus.badgeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  chargeStatus.localizedLabel(l10n),
                  style: AppTextStyles.caption.copyWith(
                    color: chargeStatus.badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // Divider
          Divider(
            height: 1,
            color: AppColors.borderStrong.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // 3 KPIs
          Row(
            children: [
              Expanded(
                child: _KpiCell(
                  label: l10n.facturationChargeDetailExpectedAmountLabel,
                  value: _formatAmount(expectedAmountInCents),
                  valueColor: AppColors.bleuArdoise,
                ),
              ),
              Expanded(
                child: _KpiCell(
                  label: l10n.facturationChargeDetailPaidAmountLabel,
                  value: _formatAmount(amountPaidInCents),
                  valueColor: AppColors.bleuArdoise,
                ),
              ),
              Expanded(
                child: _KpiCell(
                  label: l10n.facturationChargeDetailRemainingAmountLabel,
                  value: _formatAmount(_remainingInCents),
                  valueColor: _remainingInCents > 0
                      ? AppColors.terreCuite
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _KpiCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          value,
          style: AppTextStyles.moneyTabular.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
