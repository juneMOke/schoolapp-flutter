import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// A4 — le refus serveur, porté par la ligne elle-même.
class ExpenseDetailRejection extends StatelessWidget {
  final String? code;

  const ExpenseDetailRejection({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(
        AppDimensions.spacingS + AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.financeDetailDangerSoft,
        border: Border.all(color: AppColors.feeStatusDueBorder),
        borderRadius: BorderRadius.circular(AppDimensions.expenseIconBoxRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.error,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.expenseDetailRejected(expenseRejectionLabel(l10n, code)),
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
