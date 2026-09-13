import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_amount_input.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montant + devise d'engagement, et l'équivalent en direct (spec §7).
///
/// Dès que le montant est positif et la devise en francs, une ligne muette
/// dit ce qu'il vaut en dollars au taux nommé — et rappelle que le montant
/// enregistré reste en francs. Jamais affichée pour un montant en dollars, ni
/// sans taux publié (A5).
class ExpenseAmountFields extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final List<String> currencies;
  final ExchangeRate? rate;

  /// La soumission a été tentée : l'erreur du montant peut s'afficher.
  final bool touched;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onAmountChanged;

  const ExpenseAmountFields({
    super.key,
    required this.controller,
    required this.currency,
    required this.currencies,
    required this.rate,
    required this.touched,
    required this.onCurrencyChanged,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cents = ExpenseAmountInput.toCents(controller.text);
    final rate = this.rate;
    final usd = currency == CurrencyCode.cdf && cents != null && rate != null
        ? ExpenseUsdReader(rate).usdCentsOf(Money(cents, CurrencyCode.cdf))
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppDimensions.spacingM,
          runSpacing: AppDimensions.spacingM,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.expenseFormAmountMaxWidth,
              ),
              child: EteeloTextInput(
                controller: controller,
                label: l10n.expenseFormAmount,
                placeholder: currency == CurrencyCode.cdf
                    ? l10n.expenseFormAmountPlaceholderCdf
                    : l10n.expenseFormAmountPlaceholderUsd,
                required: true,
                capitalization: EteeloTextCapitalization.none,
                errorText: touched && cents == null
                    ? l10n.expenseFormAmountRequired
                    : null,
                onChanged: (_) => onAmountChanged(),
              ),
            ),
            ExpenseCurrencyField(
              currencies: currencies,
              selected: currency,
              onChanged: onCurrencyChanged,
            ),
          ],
        ),
        if (usd != null) ...[
          const SizedBox(height: AppDimensions.expenseInlineGap),
          Text(
            l10n.expenseFormUsdHint(
              ExpenseMoneyText.usd(usd),
              ExpenseMoneyText.rate(rate!),
            ),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
