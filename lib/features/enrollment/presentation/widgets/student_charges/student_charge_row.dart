import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_status_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargeRow extends StatelessWidget {
  final StudentCharge studentCharge;
  final TextEditingController amountController;
  final bool isEditable;
  final String? amountErrorText;
  final ValueChanged<String> onAmountChanged;

  const StudentChargeRow({
    super.key,
    required this.studentCharge,
    required this.amountController,
    required this.isEditable,
    required this.amountErrorText,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badgeColor = studentCharge.status.badgeColor;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            studentCharge.label,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            '${l10n.studentChargesAmountPaidLabel}: '
            '${studentCharge.amountPaidInCents.toStringAsFixed(0)} '
            '${studentCharge.currency}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            runSpacing: AppDimensions.spacingM,
            spacing: AppDimensions.spacingM,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: amountController,
                  enabled: isEditable,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onAmountChanged,
                  decoration: InputDecoration(
                    labelText: l10n.studentChargesAmountColumn,
                    errorText: amountErrorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingS,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingS,
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingS,
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.28)),
                ),
                child: Text(
                  studentCharge.status.localizedLabel(l10n),
                  style: AppTextStyles.caption.copyWith(color: badgeColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
