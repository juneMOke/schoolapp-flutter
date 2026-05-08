import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_row.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargesList extends StatelessWidget {
  final List<StudentCharge> studentCharges;
  final Map<String, TextEditingController> amountControllers;
  final Map<String, String?> amountErrors;
  final bool isEditable;
  final AppLocalizations l10n;
  final ValueChanged<String> onAmountChanged;

  const StudentChargesList({
    super.key,
    required this.studentCharges,
    required this.amountControllers,
    required this.amountErrors,
    required this.isEditable,
    required this.l10n,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    l10n.studentChargesLabelColumn,
                    style: AppTextStyles.tableHeader.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.studentChargesAmountColumn,
                      style: AppTextStyles.tableHeader.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                SizedBox(
                  width: AppDimensions.minTouchTarget,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      l10n.studentChargesActionsColumn,
                      style: AppTextStyles.tableHeader.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            itemCount: studentCharges.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final charge = studentCharges[index];
              final controller = amountControllers[charge.id];
              if (controller == null) {
                return const SizedBox.shrink();
              }

              return StudentChargeRow(
                key: ValueKey(charge.id),
                studentCharge: charge,
                amountController: controller,
                currency: charge.currency,
                amountErrorText: amountErrors[charge.id],
                isEditable: isEditable,
                onAmountChanged: onAmountChanged,
              );
            },
          ),
        ],
      ),
    );
  }
}
