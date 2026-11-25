import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/keyboard/eteelo_submit_shortcut.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le panneau de refus (spec §08) : un motif **obligatoire**, et trois motifs
/// tout prêts pour que le cas courant tienne en un geste.
///
/// Il s'ouvre dans la fiche plutôt que dans une modale par-dessus : le
/// décideur garde sous les yeux le montant, la chaîne et le fil — c'est ce
/// qu'il refuse.
class ExpenseRefusalPanel extends StatefulWidget {
  /// Rend le motif saisi, jamais vide ni blanc.
  final void Function(String reason) onConfirm;
  final VoidCallback onCancel;

  /// Le même panneau pour **signaler** une déclaration (v3) : un motif
  /// obligatoire aussi, mais l'ambre d'une alerte et non le rouge d'un
  /// refus — un signalement ne défait rien.
  final bool flagging;

  const ExpenseRefusalPanel({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    this.flagging = false,
  });

  @override
  State<ExpenseRefusalPanel> createState() => _ExpenseRefusalPanelState();
}

class _ExpenseRefusalPanelState extends State<ExpenseRefusalPanel> {
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
    widget.onConfirm(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final flagging = widget.flagging;
    final suggestions = flagging
        ? [
            l10n.expenseFlagSuggestionQuote,
            l10n.expenseFlagSuggestionVoucher,
            l10n.expenseFlagSuggestionApproval,
          ]
        : [
            l10n.expenseRefusalSuggestionQuote,
            l10n.expenseRefusalSuggestionAmount,
            l10n.expenseRefusalSuggestionDuplicate,
          ];
    final ink = flagging
        ? AppColors.feeStatusPartialInk
        : AppColors.feeStatusDue;
    final border = flagging
        ? AppColors.feeStatusPartialBorder
        : AppColors.feeStatusDueBorder;
    final icon = flagging ? Icons.flag_outlined : Icons.cancel_outlined;
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: flagging
            ? AppColors.feeStatusPartialSoft
            : AppColors.feeStatusDueSoft,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppDimensions.expenseInsetRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: AppDimensions.detailMiniIconSize, color: ink),
              const SizedBox(width: AppDimensions.spacingS),
              Flexible(
                child: Text(
                  flagging ? l10n.expenseFlagTitle : l10n.expenseRefusalTitle,
                  style: AppTextStyles.bodyStrong.copyWith(color: ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          // Ctrl+Entrée refuse, comme le bouton (le motif reste exigé).
          EteeloSubmitShortcut(
            autofocus: false,
            onSubmit: _confirm,
            child: EteeloTextInput(
              controller: _reason,
              label: flagging
                  ? l10n.expenseFlagReasonLabel
                  : l10n.expenseRefusalReasonLabel,
              placeholder: flagging
                  ? l10n.expenseFlagReasonHint
                  : l10n.expenseRefusalReasonHint,
              maxLines: 2,
              errorText: _missing
                  ? (flagging
                        ? l10n.expenseFlagReasonMissing
                        : l10n.expenseRefusalReasonMissing)
                  : null,
              onChanged: (_) {
                if (_missing) setState(() => _missing = false);
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              for (final suggestion in suggestions)
                _SuggestionChip(
                  label: suggestion,
                  ink: ink,
                  border: border,
                  onTap: () => _use(suggestion),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              EteeloButton.ghost(
                label: l10n.expenseFormCancel,
                onPressed: widget.onCancel,
                fullWidth: false,
              ),
              if (flagging)
                EteeloButton.primary(
                  label: l10n.expenseFlagConfirm,
                  icon: icon,
                  onPressed: _confirm,
                  fullWidth: false,
                )
              else
                EteeloButton.danger(
                  label: l10n.expenseRefusalConfirm,
                  icon: icon,
                  onPressed: _confirm,
                  fullWidth: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Un motif tout prêt. Tronqué à une ligne : il en dit assez pour être
/// reconnu, et le champ le montre en entier une fois choisi.
class _SuggestionChip extends StatelessWidget {
  final String label;
  final Color ink;
  final Color border;
  final VoidCallback onTap;

  const _SuggestionChip({
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
