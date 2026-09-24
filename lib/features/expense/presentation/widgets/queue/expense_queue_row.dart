import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_type_tag.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/queue/expense_age_tag.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/queue/expense_queue_row_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de la file (spec §05).
///
/// Le liseré de gauche double l'étiquette d'attente : ocre dès trois jours,
/// rouge dès cinq. Il ne porte rien seul — le nombre de jours est écrit à
/// côté.
class ExpenseQueueRow extends StatelessWidget {
  final Expense expense;
  final ExpenseType? type;
  final ExpenseUsdReader reader;
  final DateTime today;

  /// Le compte de la session : la propriété des gestes, et le « (vous) ».
  final String? accountId;

  final bool selected;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onOpen;
  final VoidCallback onRefuse;
  final ValueChanged<ExpenseGesture> onGesture;

  const ExpenseQueueRow({
    super.key,
    required this.expense,
    required this.type,
    required this.reader,
    required this.today,
    required this.accountId,
    required this.selected,
    required this.onToggleSelection,
    required this.onOpen,
    required this.onRefuse,
    required this.onGesture,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: selected ? AppColors.bleuArdoiseSoft : null,
      border: Border(
        bottom: const BorderSide(color: AppColors.border),
        left: BorderSide(
          color: expenseAgeAccent(expense, today: today),
          width: AppDimensions.expenseAccentBorderWidth,
        ),
      ),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingM,
      vertical: AppDimensions.spacingS + AppDimensions.spacingXS,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= AppDimensions.expenseRowWideMinWidth
          ? _wide(context)
          : _narrow(context),
    ),
  );

  Widget _wide(BuildContext context) => Row(
    children: [
      _Checkbox(
        expense: expense,
        selected: selected,
        onToggle: onToggleSelection,
      ),
      Expanded(
        flex: 22,
        child: _Title(expense: expense, accountId: accountId, onOpen: onOpen),
      ),
      const SizedBox(width: AppDimensions.spacingM),
      Expanded(flex: 9, child: ExpenseTypeTag(type: type, small: true)),
      const SizedBox(width: AppDimensions.spacingM),
      Expanded(
        flex: 9,
        child: _Amount(expense: expense, reader: reader),
      ),
      const SizedBox(width: AppDimensions.spacingM),
      Expanded(
        flex: 9,
        child: ExpenseAgeTag(expense: expense, today: today),
      ),
      const SizedBox(width: AppDimensions.spacingS),
      _actions,
    ],
  );

  Widget _narrow(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Checkbox(
            expense: expense,
            selected: selected,
            onToggle: onToggleSelection,
          ),
          Expanded(
            child: _Title(
              expense: expense,
              accountId: accountId,
              onOpen: onOpen,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          _Amount(expense: expense, reader: reader),
        ],
      ),
      const SizedBox(height: AppDimensions.spacingS),
      Row(
        children: [
          Flexible(child: ExpenseTypeTag(type: type, small: true)),
          const SizedBox(width: AppDimensions.spacingS),
          Flexible(
            child: ExpenseAgeTag(expense: expense, today: today),
          ),
        ],
      ),
      const SizedBox(height: AppDimensions.spacingS),
      Align(alignment: Alignment.centerRight, child: _actions),
    ],
  );

  Widget get _actions => ExpenseQueueRowActions(
    expense: expense,
    accountId: accountId,
    onRefuse: onRefuse,
    onGesture: onGesture,
    onOpen: onOpen,
  );
}

/// La case à cocher n'apparaît qu'à qui peut décider : sélectionner sans
/// pouvoir trancher n'ouvrirait qu'une barre de lot aux boutons absents.
class _Checkbox extends StatelessWidget {
  final Expense expense;
  final bool selected;
  final ValueChanged<String> onToggle;

  const _Checkbox({
    required this.expense,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => PermissionGate.access(
    kExpenseDecideAccess,
    child: Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spacingXS),
      child: Checkbox(
        value: selected,
        onChanged: (_) => onToggle(expense.id),
        visualDensity: VisualDensity.compact,
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  final Expense expense;
  final String? accountId;
  final VoidCallback onOpen;

  const _Title({
    required this.expense,
    required this.accountId,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mine = expense.isRequestedBy(accountId);
    final requester = expense.recordedByName ?? l10n.expenseNoValue;
    return InkWell(
      onTap: onOpen,
      hoverColor: AppColors.stateHover,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expense.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong,
          ),
          Text(
            [
              expense.number ?? l10n.expenseNumberPending,
              mine
                  ? l10n.expenseJoin(requester, l10n.expenseQueueYou)
                  : requester,
              expense.supplier ?? l10n.expenseNoSupplier,
            ].reduce(l10n.expenseJoin),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  final Expense expense;
  final ExpenseUsdReader reader;

  const _Amount({required this.expense, required this.reader});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usd = ExpenseMoneyText.showsUsdEquivalent(expense.currency)
        ? reader.usdCentsOf(expense.money)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(ExpenseMoneyText.of(expense), style: AppTextStyles.moneyTabular),
        if (usd != null)
          Text(
            l10n.expenseUsdEquivalent(ExpenseMoneyText.usd(usd)),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}
