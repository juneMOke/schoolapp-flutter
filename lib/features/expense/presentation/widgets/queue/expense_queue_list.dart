import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_queue_sort.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_queue_view.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/queue/expense_queue_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La file elle-même : son en-tête de tri, puis une ligne par demande.
///
/// Pas de palier « 40 de plus » comme au registre : une file qu'il faut
/// paginer est une file qu'on ne traite pas. Si elle devient longue, c'est le
/// retard qu'il faut regarder, pas la pagination.
class ExpenseQueueList extends StatelessWidget {
  final ExpenseQueueView view;
  final Map<String, ExpenseType> typesById;
  final ExpenseUsdReader reader;
  final DateTime today;
  final String? accountId;
  final ExpenseQueueSort sort;
  final Set<String> selection;
  final bool allSelected;

  final ValueChanged<ExpenseQueueSort> onSortChanged;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onToggleAll;
  final ValueChanged<Expense> onOpen;
  final ValueChanged<Expense> onRefuse;
  final void Function(Expense expense, ExpenseGesture gesture) onGesture;

  /// La barre de lot, ou `null` tant que rien n'est coché.
  final Widget? batchBar;

  const ExpenseQueueList({
    super.key,
    required this.view,
    required this.typesById,
    required this.reader,
    required this.today,
    required this.accountId,
    required this.sort,
    required this.selection,
    required this.allSelected,
    required this.onSortChanged,
    required this.onToggleSelection,
    required this.onToggleAll,
    required this.onOpen,
    required this.onRefuse,
    required this.onGesture,
    this.batchBar,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            sort: sort,
            allSelected: allSelected,
            onSortChanged: onSortChanged,
            onToggleAll: onToggleAll,
          ),
          ?batchBar,
          for (final expense in view.pending)
            ExpenseQueueRow(
              key: ValueKey(expense.id),
              expense: expense,
              type: typesById[expense.typeId],
              reader: reader,
              today: today,
              accountId: accountId,
              selected: selection.contains(expense.id),
              onToggleSelection: onToggleSelection,
              onOpen: () => onOpen(expense),
              onRefuse: () => onRefuse(expense),
              onGesture: (gesture) => onGesture(expense, gesture),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ExpenseQueueSort sort;
  final bool allSelected;
  final ValueChanged<ExpenseQueueSort> onSortChanged;
  final VoidCallback onToggleAll;

  const _Header({
    required this.sort,
    required this.allSelected,
    required this.onSortChanged,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppDimensions.spacingM,
        runSpacing: AppDimensions.spacingS,
        children: [
          PermissionGate.access(
            kExpenseDecideAccess,
            child: InkWell(
              onTap: onToggleAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: allSelected,
                    onChanged: (_) => onToggleAll(),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    l10n.expenseQueueSelectAll,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SegmentedTabFilter<ExpenseQueueSort>(
            semanticsLabel: l10n.expenseQueueSortTitle,
            selected: sort,
            onSelected: onSortChanged,
            options: [
              for (final value in ExpenseQueueSort.values)
                SegmentedTabOption(
                  label: expenseQueueSortLabel(l10n, value),
                  value: value,
                ),
            ],
          ),
          Text(
            l10n.expenseQueueOrderNote,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
