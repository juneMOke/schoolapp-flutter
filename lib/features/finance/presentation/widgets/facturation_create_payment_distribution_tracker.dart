import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationCreatePaymentDistributionTracker extends StatelessWidget {
  final int allocatedAmountInCents;
  final String currency;

  const FacturationCreatePaymentDistributionTracker({
    super.key,
    required this.allocatedAmountInCents,
    required this.currency,
  });

  String _format(int amountInCents) => formatMonetaryAmountWithCurrency(
    amount: amountInCents / 100,
    currency: currency,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasAllocations = allocatedAmountInCents > 0;
    final color = hasAllocations ? AppColors.success : AppColors.bleuArdoise;
    final icon = hasAllocations
        ? Icons.check_circle_outline
        : Icons.info_outline;
    final message = hasAllocations
        ? l10n.facturationCreatePaymentFooterTotalPayments(
            _format(allocatedAmountInCents),
          )
        : l10n.facturationCreatePaymentDistributionTrackerIdle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppDimensions.detailHeaderIconSize),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
