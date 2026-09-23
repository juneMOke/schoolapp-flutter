import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_register_view.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/register/expense_day_header.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/register/expense_register_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le registre (spec §5) : pas un tableau, une liste groupée par journée —
/// la plus récente en haut — par paliers de 40. Un registre se parcourt, il
/// ne se feuillette pas : pas de pagination numérotée.
class ExpenseRegisterList extends StatelessWidget {
  final ExpenseRegisterView view;
  final Map<String, ExpenseType> typesById;
  final ExpenseUsdReader reader;
  final ValueChanged<Expense> onOpen;
  final ValueChanged<Expense> onDuplicate;
  final VoidCallback onShowMore;

  const ExpenseRegisterList({
    super.key,
    required this.view,
    required this.typesById,
    required this.reader,
    required this.onOpen,
    required this.onDuplicate,
    required this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExpenseCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in view.groups) ...[
            ExpenseDayHeader(
              day: group.day,
              totals:
                  view.dayTotals[ExpenseDay.format(group.day)] ??
                  ExpenseTotals.of(group.expenses, reader),
            ),
            for (final expense in group.expenses)
              ExpenseRegisterRow(
                key: ValueKey(expense.id),
                expense: expense,
                type: typesById[expense.typeId],
                reader: reader,
                onOpen: () => onOpen(expense),
                onDuplicate: () => onDuplicate(expense),
              ),
          ],
          if (view.remaining > 0)
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Center(
                child: EteeloButton.secondary(
                  // Le bouton annonce le reste exact.
                  label: l10n.expenseShowMore(
                    math.min(ExpenseRegisterState.pageSize, view.remaining),
                    view.remaining,
                  ),
                  icon: Icons.expand_more,
                  onPressed: onShowMore,
                  fullWidth: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
