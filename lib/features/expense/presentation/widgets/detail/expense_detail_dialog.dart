import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_dialog_header.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_body.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la fiche demande à l'écran de faire après sa fermeture.
enum ExpenseDetailChoice { withdraw, duplicate, edit }

/// Ouvre la fiche d'une dépense. Les trois gestes offerts ferment la fiche et
/// rendent leur choix.
///
/// Le fil est **déjà lu** quand la fiche s'ouvre : `null` dit qu'il n'a pas pu
/// l'être, et une liste vide qu'il n'y a rien à lire. La fiche ne charge donc
/// rien elle-même — une lecture locale n'a pas besoin d'un écran d'attente.
Future<ExpenseDetailChoice?> showExpenseDetailDialog(
  BuildContext context, {
  required Expense expense,
  required ExpenseType? type,
  required ExpenseUsdReader reader,
  required List<ExpenseMessage>? thread,
  String? accountId,
}) => showDialog<ExpenseDetailChoice>(
  context: context,
  builder: (_) => ExpenseDetailDialog(
    expense: expense,
    type: type,
    reader: reader,
    thread: thread,
    accountId: accountId,
  ),
);

class ExpenseDetailDialog extends StatefulWidget {
  final Expense expense;
  final ExpenseType? type;
  final ExpenseUsdReader reader;
  final List<ExpenseMessage>? thread;
  final String? accountId;

  const ExpenseDetailDialog({
    super.key,
    required this.expense,
    required this.type,
    required this.reader,
    required this.thread,
    this.accountId,
  });

  @override
  State<ExpenseDetailDialog> createState() => _ExpenseDetailDialogState();
}

class _ExpenseDetailDialogState extends State<ExpenseDetailDialog> {
  late final Expense _expense = widget.expense;

  void _close([ExpenseDetailChoice? choice]) =>
      Navigator.of(context).pop(choice);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = _expense.number;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.expenseDetailDialogMaxWidth,
        ),
        child: EteeloDialogBody(
          header: ExpenseDialogHeader(
            eyebrow: number == null
                ? l10n.expenseDetailEyebrowPending
                : l10n.expenseDetailEyebrow(number),
            title: _expense.title,
            subtitle: l10n.expenseJoin(
              widget.type?.label ?? l10n.expenseTypeUnknown,
              MaterialLocalizations.of(
                context,
              ).formatFullDate(_expense.expenseDate),
            ),
            onClose: _close,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
            ),
            child: ExpenseDetailBody(
              expense: _expense,
              type: widget.type,
              reader: widget.reader,
              thread: widget.thread,
              accountId: widget.accountId,
            ),
          ),
          footer: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppDimensions.spacingS,
                runSpacing: AppDimensions.spacingS,
                children: [
                  // Supprimer : à gauche, en rouge, et seulement depuis la fiche
                  // — la fiche est déjà un pas délibéré.
                  PermissionGate.access(
                    kExpenseWithdrawAccess,
                    child: TextButton.icon(
                      onPressed: () => _close(ExpenseDetailChoice.withdraw),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.expenseActionDelete),
                    ),
                  ),
                  PermissionGate.access(
                    kExpenseWriteAccess,
                    child: Wrap(
                      spacing: AppDimensions.spacingS,
                      runSpacing: AppDimensions.spacingS,
                      children: [
                        EteeloButton.secondary(
                          label: l10n.expenseActionDuplicate,
                          icon: Icons.copy_outlined,
                          onPressed: () =>
                              _close(ExpenseDetailChoice.duplicate),
                          fullWidth: false,
                        ),
                        EteeloButton.secondary(
                          label: l10n.expenseActionEdit,
                          icon: Icons.edit_outlined,
                          onPressed: () => _close(ExpenseDetailChoice.edit),
                          fullWidth: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
