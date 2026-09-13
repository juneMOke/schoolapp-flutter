import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête d'une journée du registre : la date en toutes lettres, l'effectif
/// et le total du jour — terre cuite, la couleur du décaissement. « Qu'est-ce
/// qu'on a sorti mardi ? » se lit ici.
///
/// [totals] porte la journée ENTIÈRE, même quand le palier de 40 la coupe :
/// un en-tête ne ment pas sur ce qu'il annonce. Une lecture en dollars qui
/// convertit est doublée de sa paire brute (F9).
class ExpenseDayHeader extends StatelessWidget {
  final DateTime day;
  final ExpenseTotals totals;

  const ExpenseDayHeader({super.key, required this.day, required this.totals});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final reading = ExpenseMoneyText.reading(totals);
    final muted = AppTextStyles.caption.copyWith(color: AppColors.textMuted);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS + AppDimensions.spacingXS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.border),
        ),
      ),
      child: Wrap(
        spacing: AppDimensions.spacingS,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dates.formatFullDate(day), style: AppTextStyles.bodyStrong),
              const SizedBox(width: AppDimensions.spacingS),
              Text(l10n.expenseDayCount(totals.count), style: muted),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reading.primary,
                style: AppTextStyles.moneyTabular.copyWith(
                  color: AppColors.terreCuite,
                ),
              ),
              if (reading.pair != null) ...[
                const SizedBox(width: AppDimensions.spacingS),
                Text(reading.pair!, style: muted),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
