import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryChargeLine extends StatelessWidget {
  final StudentCharge charge;

  const SummaryChargeLine({super.key, required this.charge});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedLabel = charge.feeCode.localizedFeeLabel(l10n);
    final label = localizedLabel == l10n.studentChargeFeeCodeFallback
        ? (charge.label.trim().isEmpty ? charge.feeCode : charge.label)
        : localizedLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatMonetaryAmountWithCurrency(
              amount: charge.expectedAmountInCents,
              currency: charge.currency,
            ),
            textAlign: TextAlign.right,
            style: AppTextStyles.moneyTabular.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
