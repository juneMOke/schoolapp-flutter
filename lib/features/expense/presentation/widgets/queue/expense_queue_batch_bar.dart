import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre de lot (spec §05) : ce qui est coché, et les deux gestes qu'on
/// peut leur appliquer d'un coup.
///
/// **Le lot est un geste d'écran, pas un appel réseau** (F23) : le back a
/// retiré sa route de lot, et chaque demande produit son propre geste, son
/// propre message et sa propre entrée de file. Approuver quatre demandes,
/// c'est quatre écritures et **un** accusé de synthèse, calculé en local.
class ExpenseQueueBatchBar extends StatefulWidget {
  final int count;
  final ExpenseTotals totals;
  final VoidCallback onClear;
  final VoidCallback onApprove;

  /// Le motif est **commun**, écrit une fois et recopié dans chaque geste.
  final ValueChanged<String> onRefuse;

  const ExpenseQueueBatchBar({
    super.key,
    required this.count,
    required this.totals,
    required this.onClear,
    required this.onApprove,
    required this.onRefuse,
  });

  @override
  State<ExpenseQueueBatchBar> createState() => _ExpenseQueueBatchBarState();
}

class _ExpenseQueueBatchBarState extends State<ExpenseQueueBatchBar> {
  final TextEditingController _reason = TextEditingController();
  bool _refusing = false;
  bool _missing = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    widget.onRefuse(reason);
    setState(() {
      _refusing = false;
      _missing = false;
    });
    _reason.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usd = widget.totals.usdCents;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: const BoxDecoration(
        color: AppColors.bleuArdoiseSoft,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              Text(
                // Sans taux publié, la barre compte les demandes et se tait
                // sur la somme : un total partiel mentirait sans le dire (A5).
                usd == null
                    ? l10n.expenseQueueSelected(widget.count)
                    : l10n.expenseJoin(
                        l10n.expenseQueueSelected(widget.count),
                        ExpenseMoneyText.usd(usd),
                      ),
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
              EteeloButton.ghost(
                label: l10n.expenseQueueDeselect,
                onPressed: widget.onClear,
                fullWidth: false,
              ),
              EteeloButton.secondary(
                label: l10n.expenseQueueRefuseBatch,
                icon: Icons.cancel_outlined,
                onPressed: () => setState(() => _refusing = true),
                fullWidth: false,
              ),
              EteeloButton.primary(
                label: l10n.expenseQueueApproveBatch,
                icon: Icons.verified_outlined,
                onPressed: widget.onApprove,
                fullWidth: false,
              ),
            ],
          ),
          if (_refusing) _panel(l10n),
        ],
      ),
    );
  }

  Widget _panel(AppLocalizations l10n) => Container(
    margin: const EdgeInsets.only(top: AppDimensions.spacingM),
    padding: const EdgeInsets.all(AppDimensions.spacingM),
    decoration: BoxDecoration(
      color: AppColors.feeStatusDueSoft,
      border: Border.all(color: AppColors.feeStatusDueBorder),
      borderRadius: BorderRadius.circular(AppDimensions.expenseInsetRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloTextInput(
          controller: _reason,
          label: l10n.expenseQueueBatchReasonLabel(widget.count),
          placeholder: l10n.expenseQueueBatchReasonHint,
          maxLines: 2,
          errorText: _missing ? l10n.expenseRefusalReasonMissing : null,
          onChanged: (_) {
            if (_missing) setState(() => _missing = false);
          },
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            EteeloButton.ghost(
              label: l10n.expenseFormCancel,
              onPressed: () => setState(() {
                _refusing = false;
                _missing = false;
              }),
              fullWidth: false,
            ),
            EteeloButton.danger(
              label: l10n.expenseQueueBatchConfirm(widget.count),
              icon: Icons.cancel_outlined,
              onPressed: _confirm,
              fullWidth: false,
            ),
          ],
        ),
      ],
    ),
  );
}
