import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_advance_payment.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Décaisser une avance au personnel (B6, T13) : le rappel de l'accord, la
/// preuve — reconnaissance de dette signée en espèces, référence sinon — et
/// la paie de la première retenue. Rend le décaissement, ou `null`.
class ExpenseAdvancePayDialog extends StatefulWidget {
  final Expense expense;

  /// Les mois proposés pour la première retenue, `YYYY-MM`, le plus proche
  /// d'abord.
  final List<String> months;
  final String Function(String month) monthLabel;

  const ExpenseAdvancePayDialog({
    super.key,
    required this.expense,
    required this.months,
    required this.monthLabel,
  });

  static Future<ExpenseAdvancePayment?> show(
    BuildContext context,
    ExpenseAdvancePayDialog dialog,
  ) => EteeloFormDialog.show<ExpenseAdvancePayment>(context, dialog);

  @override
  State<ExpenseAdvancePayDialog> createState() =>
      _ExpenseAdvancePayDialogState();
}

class _ExpenseAdvancePayDialogState extends State<ExpenseAdvancePayDialog> {
  late String _month = widget.months.first;
  bool _acknowledged = false;
  final TextEditingController _reference = TextEditingController();

  bool get _cash => widget.expense.fundingSource == ExpenseFundingSource.cash;

  bool get _complete => _cash
      ? _acknowledged
      : _reference.text.trim().length >=
            ExpenseAdvancePayment.minReferenceLength;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_complete) return;
    Navigator.of(context).pop(
      ExpenseAdvancePayment(
        firstMonth: _month,
        debtAcknowledged: _cash && _acknowledged,
        reference: _cash ? null : _reference.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expense = widget.expense;
    final amount = MoneyFormat.format(expense.money);
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    return EteeloFormDialog(
      onSubmit: _complete ? _submit : null,
      eyebrow: expense.title,
      title: l10n.expenseAdvancePayTitle(amount),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expense.decidedByName case final by?)
            Text(l10n.expenseAdvancePayApprovedBy(by), style: muted),
          Text(
            l10n.expenseAdvancePayMode(
              expenseFundingLabel(l10n, expense.fundingSource),
            ),
            style: muted,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_cash)
            CheckboxListTile(
              value: _acknowledged,
              onChanged: (value) =>
                  setState(() => _acknowledged = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.expenseAdvancePayAcknowledged),
            )
          else
            EteeloTextInput(
              controller: _reference,
              label: l10n.expenseAdvancePayReference,
              required: true,
              capitalization: EteeloTextCapitalization.none,
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.expenseAdvancePayFirstMonth,
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final month in widget.months)
                EteeloFilterChip(
                  label: widget.monthLabel(month),
                  selected: month == _month,
                  color: AppColors.terreCuite,
                  soft: AppColors.terreCuiteSoft,
                  ink: AppColors.terreCuiteDark,
                  onTap: () => setState(() => _month = month),
                ),
            ],
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.expenseFormCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.expenseAdvancePayConfirm(amount),
          icon: Icons.payments_outlined,
          onPressed: _complete ? _submit : null,
          fullWidth: false,
        ),
      ],
    );
  }
}
