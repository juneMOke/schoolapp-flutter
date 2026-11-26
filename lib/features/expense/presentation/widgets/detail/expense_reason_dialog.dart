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
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Demande le motif d'un refus, dans une modale **par-dessus** la fiche
/// (recette staging) : un panneau ouvert en bas de la fiche restait hors de
/// vue, et la fiche reste derrière, sous les yeux.
///
/// Rend le motif saisi, jamais vide ni blanc, ou `null` si l'on renonce.
Future<String?> showExpenseRefusalDialog(
  BuildContext context, {
  required Expense expense,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (_) => ExpenseReasonDialog(
      expense: expense,
      title: l10n.expenseRefusalTitle,
      label: l10n.expenseRefusalReasonLabel,
      placeholder: l10n.expenseRefusalReasonHint,
      missing: l10n.expenseRefusalReasonMissing,
      confirm: l10n.expenseRefusalConfirm,
      suggestions: [
        l10n.expenseRefusalSuggestionQuote,
        l10n.expenseRefusalSuggestionAmount,
        l10n.expenseRefusalSuggestionDuplicate,
      ],
      tone: ExpenseReasonTone.refusal,
    ),
  );
}

/// Demande le motif d'un signalement, même modale que le refus.
Future<String?> showExpenseFlagDialog(
  BuildContext context, {
  required Expense expense,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (_) => ExpenseReasonDialog(
      expense: expense,
      title: l10n.expenseFlagTitle,
      hint: l10n.expenseFlagDialogHint,
      label: l10n.expenseFlagReasonLabel,
      placeholder: l10n.expenseFlagReasonHint,
      missing: l10n.expenseFlagReasonMissing,
      confirm: l10n.expenseFlagConfirm,
      suggestions: [
        l10n.expenseFlagSuggestionQuote,
        l10n.expenseFlagSuggestionVoucher,
        l10n.expenseFlagSuggestionApproval,
      ],
      tone: ExpenseReasonTone.flag,
    ),
  );
}

/// Le refus est rouge et terminal pour la demande ; le signalement est ambre,
/// la dépense reste payée.
enum ExpenseReasonTone {
  refusal(
    ink: AppColors.feeStatusDue,
    border: AppColors.feeStatusDueBorder,
    icon: Icons.cancel_outlined,
  ),
  flag(
    ink: AppColors.feeStatusPartialInk,
    border: AppColors.feeStatusPartialBorder,
    icon: Icons.flag_outlined,
  );

  final Color ink;
  final Color border;
  final IconData icon;

  const ExpenseReasonTone({
    required this.ink,
    required this.border,
    required this.icon,
  });
}

/// Un motif **obligatoire**, et trois motifs tout prêts pour que le cas
/// courant tienne en un geste.
class ExpenseReasonDialog extends StatefulWidget {
  final Expense expense;
  final String title;
  final String? hint;
  final String label;
  final String placeholder;
  final String missing;
  final String confirm;
  final List<String> suggestions;
  final ExpenseReasonTone tone;

  const ExpenseReasonDialog({
    super.key,
    required this.expense,
    required this.title,
    this.hint,
    required this.label,
    required this.placeholder,
    required this.missing,
    required this.confirm,
    required this.suggestions,
    required this.tone,
  });

  @override
  State<ExpenseReasonDialog> createState() => _ExpenseReasonDialogState();
}

class _ExpenseReasonDialogState extends State<ExpenseReasonDialog> {
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
    final tone = widget.tone;
    final hint = widget.hint;
    void close() => Navigator.of(context).pop();
    return EteeloAdaptiveDialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      maxWidth: AppDimensions.confirmationDialogMaxWidth,
      // Ctrl+Entrée confirme, comme le bouton (le motif reste exigé).
      child: EteeloSubmitShortcut(
        onSubmit: _confirm,
        onCancel: close,
        child: EteeloDialogBody(
          header: ExpenseDialogHeader(
            eyebrow: widget.expense.number ?? l10n.expenseNumberPending,
            title: widget.title,
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
                if (hint != null) ...[
                  Text(
                    hint,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                ],
                EteeloTextInput(
                  controller: _reason,
                  label: widget.label,
                  placeholder: widget.placeholder,
                  required: true,
                  autofocus: true,
                  maxLines: 3,
                  errorText: _missing ? widget.missing : null,
                  onChanged: (_) {
                    if (_missing) setState(() => _missing = false);
                  },
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Wrap(
                  spacing: AppDimensions.spacingS,
                  runSpacing: AppDimensions.spacingS,
                  children: [
                    for (final suggestion in widget.suggestions)
                      ExpenseReasonChip(
                        label: suggestion,
                        ink: tone.ink,
                        border: tone.border,
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
                  if (tone == ExpenseReasonTone.refusal)
                    EteeloButton.danger(
                      label: widget.confirm,
                      icon: tone.icon,
                      onPressed: _confirm,
                      fullWidth: false,
                    )
                  else
                    EteeloButton.primary(
                      label: widget.confirm,
                      icon: tone.icon,
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

/// Un motif tout prêt. Tronqué à une ligne : il en dit assez pour être
/// reconnu, et le champ le montre en entier une fois choisi.
class ExpenseReasonChip extends StatelessWidget {
  final String label;
  final Color ink;
  final Color border;
  final VoidCallback onTap;

  const ExpenseReasonChip({
    super.key,
    required this.label,
    required this.ink,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: AppDimensions.expenseRefusalChipMaxWidth,
    ),
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: AppColors.surfaceRaised,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingS + AppDimensions.spacingXS,
          vertical: AppDimensions.spacingXS,
        ),
        // Sans taille minimale, un bouton posé dans un Wrap réclame une
        // largeur infinie et emporte la modale avec lui.
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}
