import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_wait.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Depuis combien de temps une demande attend — le repère qui se lit d'un
/// coup d'œil sur une file de trente lignes (spec §05).
///
/// Deux paliers et une icône, jamais une couleur seule : **tiède à 3 jours**
/// (ocre), **chaud à 5** (rouge, et l'icône devient un avertissement). Le
/// nombre de jours est toujours écrit — c'est lui qui porte l'information.
class ExpenseAgeTag extends StatelessWidget {
  final Expense expense;
  final DateTime today;

  /// Le compteur de relances à côté de l'attente : deux faits distincts —
  /// elle attend, et quelqu'un a déjà poussé.
  final bool showReminders;

  const ExpenseAgeTag({
    super.key,
    required this.expense,
    required this.today,
    this.showReminders = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = ExpenseWait.daysWaiting(expense, today: today);
    final hot = days >= ExpenseWait.hotDays;
    final warm = days >= ExpenseWait.warmDays;
    final ink = hot
        ? AppColors.feeStatusDue
        : warm
        ? AppColors.feeStatusPartialInk
        : AppColors.textMuted;
    final reminders = expense.reminderCount;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppDimensions.expenseInlineGap,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hot ? Icons.warning_amber_rounded : Icons.schedule,
              size: AppDimensions.expenseStatusIconSizeSmall,
              color: ink,
            ),
            const SizedBox(width: AppDimensions.expenseInlineGap),
            // `Flexible` et non `Text` nu : « depuis 10 jours » dépasse la
            // colonne d'attente d'une ligne serrée, et une `Row` en
            // `MainAxisSize.min` déborde sans jamais rogner d'elle-même.
            Flexible(
              child: Text(
                days == 0
                    ? l10n.expenseQueueWaitingToday
                    : l10n.expenseQueueWaitingDays(days),
                style: AppTextStyles.caption.copyWith(color: ink),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (showReminders && reminders > 0)
          Text(
            l10n.expenseQueueReminderCount(reminders),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.feeStatusPartialInk,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// La teinte du liseré de gauche d'une ligne de file : rien tant que la
/// demande est fraîche, ocre quand elle traîne, rouge quand elle est en
/// retard. Il double l'étiquette, il ne la remplace pas.
Color expenseAgeAccent(Expense expense, {required DateTime today}) {
  final days = ExpenseWait.daysWaiting(expense, today: today);
  if (days >= ExpenseWait.hotDays) return AppColors.feeStatusDue;
  if (days >= ExpenseWait.warmDays) return AppColors.feeStatusPartial;
  return Colors.transparent;
}
