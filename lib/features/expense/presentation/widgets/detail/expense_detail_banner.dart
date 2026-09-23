import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_type_visuals.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_status_badge.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_type_tag.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La tête de la fiche : le montant à l'échelle du titre — c'est le fait que
/// l'on vient vérifier — et l'état du circuit à côté.
class ExpenseDetailBanner extends StatelessWidget {
  final Expense expense;
  final ExpenseType? type;
  final ExpenseUsdReader reader;

  const ExpenseDetailBanner({
    super.key,
    required this.expense,
    required this.type,
    required this.reader,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ExpenseTypeColors.of(type);
    final usd = ExpenseMoneyText.showsUsdEquivalent(expense.currency)
        ? reader.usdCentsOf(Money(expense.amountInCents, expense.currency))
        : null;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: colors.soft,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.expenseInsetRadius),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.expenseDetailMedallionSize,
            height: AppDimensions.expenseDetailMedallionSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(
                AppDimensions.expenseInsetRadius,
              ),
            ),
            child: Icon(
              type == null
                  ? ExpenseTypeVisuals.fallbackIcon
                  : ExpenseTypeVisuals.icon(type!.icon),
              size: AppDimensions.expenseDetailMedallionIconSize,
              color: colors.color,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ExpenseMoneyText.of(expense),
                  style: AppTextStyles.totalAmountLora,
                ),
                if (usd != null)
                  Text(
                    l10n.expenseUsdEquivalentOfDay(ExpenseMoneyText.usd(usd)),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          ExpenseStatusBadge(status: expense.status),
        ],
      ),
    );
  }
}
