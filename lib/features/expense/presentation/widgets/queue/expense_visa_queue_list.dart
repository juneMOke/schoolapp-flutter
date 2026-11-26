import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_status_badge.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/queue/expense_voucher_thumb.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_declaration_delay.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La file « À viser » (v3) : les déclarations que le promoteur n'a pas
/// encore visées, de la plus ancienne sortie à la plus récente, photo en
/// vignette. Une ligne ouvre la fiche — c'est là qu'on vise, le bon sous
/// les yeux, jamais d'un clic de liste.
class ExpenseVisaQueueList extends StatelessWidget {
  final List<Expense> expenses;
  final Map<String, ExpenseType> typesById;
  final ValueChanged<Expense> onOpen;

  const ExpenseVisaQueueList({
    super.key,
    required this.expenses,
    required this.typesById,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (expenses.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.expenseQueueVisaEmptyTitle,
        description: l10n.expenseQueueVisaEmpty,
        medallionIcon: Icons.verified_outlined,
      );
    }
    return ExpenseCard(
      child: Column(
        children: [
          for (final (i, expense) in expenses.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _VisaRow(
              // Sans clé, une ligne remontée garderait la vignette de celle
              // qu'elle remplace — le mauvais bon sous les yeux de qui vise.
              key: ValueKey(expense.id),
              expense: expense,
              type: typesById[expense.typeId],
              onOpen: () => onOpen(expense),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisaRow extends StatelessWidget {
  final Expense expense;
  final ExpenseType? type;
  final VoidCallback onOpen;

  const _VisaRow({
    super.key,
    required this.expense,
    required this.type,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final disbursed = expense.disbursedAt;
    final lateDays = ExpenseDeclarationDelay.days(expense) ?? 0;
    final out = disbursed == null
        ? expense.expenseDate
        : SchoolTime.wallClock(disbursed);
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Row(
          children: [
            ExpenseVoucherThumb(expense: expense),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: AppTextStyles.bodyStrong,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    l10n.expenseJoin(
                      type?.label ?? l10n.expenseTypeUnknown,
                      dates.formatMediumDate(out),
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (lateDays >= 1) ...[
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.expenseDeclaredAfterDays(lateDays),
                      style: AppTextStyles.caption.copyWith(
                        // Au-delà de 72 h, l'ambre d'une alerte : le serveur
                        // n'a pas posé le visa d'office.
                        color: ExpenseDeclarationDelay.isLate(expense)
                            ? AppColors.feeStatusPartialInk
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spacingXS),
                  Wrap(
                    spacing: AppDimensions.spacingS,
                    runSpacing: AppDimensions.spacingXS,
                    children: [
                      ExpenseVisaBadge(expense: expense),
                      ExpenseSyncBadge(expense: expense),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Text(ExpenseMoneyText.of(expense), style: AppTextStyles.bodyStrong),
          ],
        ),
      ),
    );
  }
}
