import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_status_badge.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_type_tag.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/register/expense_row_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne du registre (spec §5) : la ligne entière ouvre la fiche ; deux
/// gestes seulement à portée de main — basculer le statut et dupliquer. Un
/// geste destructeur ne doit jamais être à un pixel d'un geste quotidien.
///
/// ≥ 820 dp : cinq colonnes. En dessous : deux rangées, intitulé et montant
/// au-dessus, type, statut et actions en dessous — rien ne disparaît.
class ExpenseRegisterRow extends StatelessWidget {
  final Expense expense;
  final ExpenseType? type;
  final ExpenseUsdReader reader;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onDuplicate;

  const ExpenseRegisterRow({
    super.key,
    required this.expense,
    required this.type,
    required this.reader,
    required this.onOpen,
    required this.onToggle,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      hoverColor: AppColors.stateHover,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS + AppDimensions.spacingXS,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= AppDimensions.expenseRowWideMinWidth
              ? _wide(context)
              : _narrow(context),
        ),
      ),
    );
  }

  Widget _wide(BuildContext context) => Row(
    children: [
      Expanded(flex: 24, child: _Title(expense: expense)),
      const SizedBox(width: AppDimensions.spacingM),
      Expanded(flex: 10, child: ExpenseTypeTag(type: type, small: true)),
      const SizedBox(width: AppDimensions.spacingM),
      Expanded(
        flex: 9,
        child: _Amount(expense: expense, reader: reader),
      ),
      const SizedBox(width: AppDimensions.spacingM),
      Expanded(flex: 8, child: _Badges(expense: expense)),
      ExpenseRowActions(
        expense: expense,
        onToggle: onToggle,
        onDuplicate: onDuplicate,
      ),
    ],
  );

  Widget _narrow(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Title(expense: expense)),
          const SizedBox(width: AppDimensions.spacingS),
          _Amount(expense: expense, reader: reader),
        ],
      ),
      const SizedBox(height: AppDimensions.spacingS),
      Row(
        children: [
          Flexible(child: ExpenseTypeTag(type: type, small: true)),
          const SizedBox(width: AppDimensions.spacingS),
          Flexible(child: _Badges(expense: expense)),
          const Spacer(),
          ExpenseRowActions(
            expense: expense,
            onToggle: onToggle,
            onDuplicate: onDuplicate,
          ),
        ],
      ),
    ],
  );
}

class _Title extends StatelessWidget {
  final Expense expense;

  const _Title({required this.expense});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
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
            expense.supplier ?? l10n.expenseNoSupplier,
            expenseFundingLabel(l10n, expense.fundingSource),
          ].reduce(l10n.expenseJoin),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
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
        ? reader.usdCentsOf(Money(expense.amountInCents, expense.currency))
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(ExpenseMoneyText.of(expense), style: AppTextStyles.moneyTabular),
        // L'équivalent accompagne, il ne remplace pas ; une ligne en dollars
        // n'en a pas.
        if (usd != null)
          Text(
            l10n.expenseUsdEquivalent(ExpenseMoneyText.usd(usd)),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}

class _Badges extends StatelessWidget {
  final Expense expense;

  const _Badges({required this.expense});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppDimensions.spacingXS,
    runSpacing: AppDimensions.spacingXS,
    children: [
      ExpenseStatusBadge(status: expense.status, small: true),
      ExpenseSyncBadge(expense: expense),
    ],
  );
}
