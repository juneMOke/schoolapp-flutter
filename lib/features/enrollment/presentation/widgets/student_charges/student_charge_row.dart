import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargeRow extends StatelessWidget {
  final StudentCharge studentCharge;
  final TextEditingController amountController;
  final bool isEditable;
  final String currency;
  final String? amountErrorText;
  final ValueChanged<String> onAmountChanged;

  const StudentChargeRow({
    super.key,
    required this.studentCharge,
    required this.amountController,
    required this.isEditable,
    required this.currency,
    required this.amountErrorText,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedLabel = studentCharge.feeCode.localizedFeeLabel(l10n);
    final fallbackLabel = studentCharge.label.isNotEmpty
        ? studentCharge.label
        : studentCharge.feeCode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedLabel == l10n.studentChargeFeeCodeFallback
                      ? fallbackLabel
                      : localizedLabel,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  studentCharge.feeCode,
                  style: AppTextStyles.codeMuted.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            flex: 4,
            child: CurrencyField(
              controller: amountController,
              currency: currency,
              enabled: isEditable,
              labelText: l10n.studentChargesAmountColumn,
              errorText: amountErrorText,
              onChanged: onAmountChanged,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          SizedBox(
            width: AppDimensions.minTouchTarget,
            child: Center(
              child: Icon(
                isEditable ? Icons.edit_outlined : Icons.lock_outline,
                size: AppDimensions.detailMiniIconSize,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
