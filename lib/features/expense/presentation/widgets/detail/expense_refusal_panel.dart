import 'package:flutter/material.dart';
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

  const ExpenseRefusalPanel({
    super.key,
    required this.onConfirm,
    required this.onCancel,
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
    final suggestions = [
      l10n.expenseRefusalSuggestionQuote,
      l10n.expenseRefusalSuggestionAmount,
      l10n.expenseRefusalSuggestionDuplicate,
    ];
    return Container(
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
          Row(
            children: [
              const Icon(
                Icons.cancel_outlined,
                size: AppDimensions.detailMiniIconSize,
                color: AppColors.feeStatusDue,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.expenseRefusalTitle,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.feeStatusDue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          EteeloTextInput(
            controller: _reason,
            label: l10n.expenseRefusalReasonLabel,
            placeholder: l10n.expenseRefusalReasonHint,
            maxLines: 2,
            errorText: _missing ? l10n.expenseRefusalReasonMissing : null,
            onChanged: (_) {
              if (_missing) setState(() => _missing = false);
            },
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              for (final suggestion in suggestions)
                _SuggestionChip(
                  label: suggestion,
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
              EteeloButton.danger(
                label: l10n.expenseRefusalConfirm,
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
}

/// Un motif tout prêt. Tronqué à une ligne : il en dit assez pour être
/// reconnu, et le champ le montre en entier une fois choisi.
class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: AppDimensions.expenseRefusalChipMaxWidth,
    ),
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.feeStatusDue,
        backgroundColor: AppColors.surfaceRaised,
        side: const BorderSide(color: AppColors.feeStatusDueBorder),
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
