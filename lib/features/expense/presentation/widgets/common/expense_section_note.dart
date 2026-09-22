import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Note de bas de section — la provenance d'un chiffre (le taux nommé).
class ExpenseSectionNote extends StatelessWidget {
  final String text;

  const ExpenseSectionNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: AppDimensions.spacingM),
    padding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingS + AppDimensions.spacingXS,
      vertical: AppDimensions.expenseNotePaddingV,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppDimensions.expenseIconBoxRadius),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: AppDimensions.detailMiniIconSize,
          color: AppColors.textMutedAa,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Le taux nommé sous les chiffres clés (F9, doctrine bi-devise §12) : dès
/// qu'une lecture en dollars convertit du franc, l'écran dit à quel taux.
///
/// Rien quand il n'y a rien à convertir, ni sans taux — les cartes empilent
/// alors leurs devises, et le disent.
class ExpenseRateNote extends StatelessWidget {
  final ExchangeRate? rate;
  final ExpenseTotals totals;

  const ExpenseRateNote({super.key, required this.rate, required this.totals});

  @override
  Widget build(BuildContext context) {
    final rate = this.rate;
    final converts =
        totals.usdCents != null &&
        totals.bag.currencies.any(ExpenseMoneyText.showsUsdEquivalent);
    if (rate == null || !converts) return const SizedBox.shrink();
    return ExpenseSectionNote(
      text: AppLocalizations.of(
        context,
      )!.expenseRateNote(ExpenseMoneyText.rate(rate)),
    );
  }
}
