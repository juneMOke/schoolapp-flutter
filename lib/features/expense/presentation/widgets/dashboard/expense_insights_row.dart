import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_dashboard_view.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_insight_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois encarts de lecture : où part l'argent, ce qui reste à régler,
/// et ce que vaut le total affiché (une lecture, pas une conversion).
class ExpenseInsightsRow extends StatelessWidget {
  final ExpenseDashboardView view;

  /// « ce mois-ci » — la granularité, accordée.
  final String demonstrative;
  final ExchangeRate? rate;
  final VoidCallback onOpenRegister;

  const ExpenseInsightsRow({
    super.key,
    required this.view,
    required this.demonstrative,
    required this.rate,
    required this.onOpenRegister,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      _whereMoneyGoes(l10n),
      _remaining(context, l10n),
      _biCurrency(l10n),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppDimensions.spacingM;
        final fitsThree =
            constraints.maxWidth >=
            3 * AppDimensions.expenseInsightMinWidth + 2 * gap;
        final width = fitsThree
            ? ((constraints.maxWidth - 2 * gap) / 3).floorToDouble()
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  Widget _whereMoneyGoes(AppLocalizations l10n) {
    final top = view.shares.take(3).toList(growable: false);
    final labels = top
        .map((s) => s.type?.shortLabel ?? l10n.expenseTypeUnknown)
        .join(', ');
    final topUsd = top.fold<int?>(
      0,
      (sum, s) => sum == null || s.totals.usdCents == null
          ? null
          : sum + s.totals.usdCents!,
    );
    final total = view.total.usdCents;
    final String body;
    if (top.isEmpty) {
      body = l10n.expenseInsightWhereNone(demonstrative);
    } else if (topUsd != null && total != null && total > 0) {
      body = l10n.expenseInsightWhereBody(
        labels,
        (topUsd * 100 / total).round(),
      );
    } else {
      body = l10n.expenseInsightWhereByCount(labels);
    }
    return ExpenseInsightCard(
      icon: Icons.account_balance_wallet_outlined,
      accent: AppColors.terreCuite,
      accentSoft: AppColors.terreCuiteSoft,
      title: l10n.expenseInsightWhereTitle,
      body: body,
      actionLabel: l10n.expenseOpenRegister,
      onAction: onOpenRegister,
    );
  }

  Widget _remaining(BuildContext context, AppLocalizations l10n) {
    final unpaid = view.unpaid;
    final oldest = view.oldestUnpaid;
    if (unpaid.isEmpty || oldest == null) {
      return ExpenseInsightCard(
        icon: Icons.check_circle_outline,
        accent: AppColors.feeStatusPaid,
        accentSoft: AppColors.feeStatusPaidSoft,
        title: l10n.expenseInsightRemainingTitle,
        body: l10n.expenseInsightAllPaid(demonstrative),
      );
    }
    final reading = ExpenseMoneyText.reading(unpaid);
    final amount = reading.pair == null
        ? reading.primary
        : l10n.expenseReadingWithPair(reading.primary, reading.pair!);
    return ExpenseInsightCard(
      icon: Icons.schedule,
      accent: AppColors.feeStatusPartial,
      accentSoft: AppColors.feeStatusPartialSoft,
      title: l10n.expenseInsightRemainingTitle,
      body: l10n.expenseInsightUnpaidBody(
        unpaid.count,
        amount,
        MaterialLocalizations.of(context).formatMediumDate(oldest.expenseDate),
      ),
    );
  }

  Widget _biCurrency(AppLocalizations l10n) {
    final rate = this.rate;
    final bag = view.total.bag;
    String part(String currency) =>
        MoneyFormat.format(bag.amountIn(currency) ?? Money(0, currency));
    return ExpenseInsightCard(
      icon: Icons.currency_exchange,
      accent: AppColors.bleuArdoise,
      accentSoft: AppColors.bleuArdoiseSoft,
      title: l10n.expenseInsightCurrencyTitle,
      body: rate == null
          ? l10n.expenseInsightNoRateBody
          : l10n.expenseInsightCurrencyBody(
              part(CurrencyCode.cdf),
              part(CurrencyCode.usd),
              ExpenseMoneyText.rate(rate),
            ),
    );
  }
}
