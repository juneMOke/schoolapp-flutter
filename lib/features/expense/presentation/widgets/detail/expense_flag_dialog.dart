import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/keyboard/eteelo_submit_shortcut.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_dialog_header.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_refusal_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Demande le motif d'un signalement, dans une modale **par-dessus** la
/// fiche (recette staging) : sous la photo du bon, un panneau ouvert en bas
/// de la fiche restait hors de vue.
///
/// Rend le motif saisi, jamais vide ni blanc, ou `null` si l'on renonce.
Future<String?> showExpenseFlagDialog(
  BuildContext context, {
  required Expense expense,
}) => showDialog<String>(
  context: context,
  builder: (_) => ExpenseFlagDialog(expense: expense),
);

class ExpenseFlagDialog extends StatefulWidget {
  final Expense expense;

  const ExpenseFlagDialog({super.key, required this.expense});

  @override
  State<ExpenseFlagDialog> createState() => _ExpenseFlagDialogState();
}

class _ExpenseFlagDialogState extends State<ExpenseFlagDialog> {
  final TextEditingController _reason = TextEditingController();
  bool _missing = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _use(String suggestion) {
    // `text =` plutôt qu'une frappe simulée : poser la même valeur qu'un champ
    // porte déjà ne déclencherait aucun `onChanged`.
    _reason.text = suggestion;
    setState(() => _missing = false);
  }

  void _confirm() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void close() => Navigator.of(context).pop();
    return EteeloAdaptiveDialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      maxWidth: AppDimensions.confirmationDialogMaxWidth,
      child: EteeloSubmitShortcut(
        onSubmit: _confirm,
        onCancel: close,
        child: EteeloDialogBody(
          header: ExpenseDialogHeader(
            eyebrow: widget.expense.number ?? l10n.expenseNumberPending,
            title: l10n.expenseFlagTitle,
            subtitle: widget.expense.title,
            onClose: close,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingL,
              AppDimensions.spacingS,
              AppDimensions.spacingL,
              AppDimensions.spacingM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.expenseFlagDialogHint,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                EteeloTextInput(
                  controller: _reason,
                  label: l10n.expenseFlagReasonLabel,
                  placeholder: l10n.expenseFlagReasonHint,
                  required: true,
                  autofocus: true,
                  maxLines: 3,
                  errorText: _missing ? l10n.expenseFlagReasonMissing : null,
                  onChanged: (_) {
                    if (_missing) setState(() => _missing = false);
                  },
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Wrap(
                  spacing: AppDimensions.spacingS,
                  runSpacing: AppDimensions.spacingS,
                  children: [
                    for (final suggestion in [
                      l10n.expenseFlagSuggestionQuote,
                      l10n.expenseFlagSuggestionVoucher,
                      l10n.expenseFlagSuggestionApproval,
                    ])
                      ExpenseReasonChip(
                        label: suggestion,
                        ink: AppColors.feeStatusPartialInk,
                        border: AppColors.feeStatusPartialBorder,
                        onTap: () => _use(suggestion),
                      ),
                  ],
                ),
              ],
            ),
          ),
          footer: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: AppDimensions.spacingS,
                runSpacing: AppDimensions.spacingS,
                children: [
                  EteeloButton.ghost(
                    label: l10n.expenseFormCancel,
                    onPressed: close,
                    fullWidth: false,
                  ),
                  EteeloButton.primary(
                    label: l10n.expenseFlagConfirm,
                    icon: Icons.flag_outlined,
                    onPressed: _confirm,
                    fullWidth: false,
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
