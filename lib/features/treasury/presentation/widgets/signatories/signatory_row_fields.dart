import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';
import 'package:school_app_flutter/features/treasury/domain/services/report_signatory_rules.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne en cours d'édition : ses champs, et une clé stable pour que
/// monter, descendre ou retirer une ligne ne mélange jamais les saisies.
class SignatoryDraft {
  static var _next = 0;

  final Key key = ValueKey('signatory-draft-${_next++}');
  final TextEditingController caption;
  final TextEditingController name;
  final TextEditingController function;
  bool filledByCloser;

  SignatoryDraft.of(ReportSignatory? s)
    : caption = TextEditingController(text: s?.caption ?? ''),
      name = TextEditingController(text: s?.name ?? ''),
      function = TextEditingController(text: s?.function ?? ''),
      filledByCloser = s?.filledByCloser ?? false;

  ReportSignatory toSignatory(int rank) => ReportSignatory(
    rank: rank,
    caption: caption.text,
    name: name.text,
    function: function.text,
    filledByCloser: filledByCloser,
  );

  void dispose() {
    caption.dispose();
    name.dispose();
    function.dispose();
  }
}

/// Les champs d'un bloc : légende, nom (facultatif), fonction, et, au premier
/// rang seulement, « la personne qui a clôturé ».
class SignatoryRowFields extends StatelessWidget {
  final SignatoryDraft draft;
  final int index;
  final int count;
  final bool enabled;
  final bool showErrors;
  final VoidCallback onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  const SignatoryRowFields({
    super.key,
    required this.draft,
    required this.index,
    required this.count,
    required this.enabled,
    required this.showErrors,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final captionBad =
        showErrors && !ReportSignatoryRules.isCaptionValid(draft.caption.text);
    final functionBad =
        showErrors &&
        !ReportSignatoryRules.isFunctionValid(draft.function.text);
    final nameBad =
        showErrors && !ReportSignatoryRules.isNameValid(draft.name.text);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.treasurySignatoryBlock(index + 1),
                  style: AppTypography.titleSmall,
                ),
              ),
              IconButton(
                tooltip: l10n.treasurySignatoryUp(index + 1),
                onPressed: enabled && index > 0 ? () => onMove(-1) : null,
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: l10n.treasurySignatoryDown(index + 1),
                onPressed: enabled && index + 1 < count
                    ? () => onMove(1)
                    : null,
                icon: const Icon(Icons.arrow_downward),
              ),
              IconButton(
                tooltip: l10n.treasurySignatoryRemove(index + 1),
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          EteeloTextInput(
            controller: draft.caption,
            label: l10n.treasurySignatoryCaption,
            placeholder: l10n.treasurySignatoryCaptionHint,
            required: true,
            enabled: enabled,
            // Une légende s'imprime en capitales, telle que saisie.
            capitalization: EteeloTextCapitalization.none,
            errorText: captionBad
                ? l10n.treasurySignatoryCaptionRequired
                : null,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.sm),
          EteeloTextInput(
            controller: draft.name,
            label: l10n.treasurySignatoryName,
            placeholder: l10n.treasurySignatoryNameHint,
            enabled: enabled,
            capitalization: EteeloTextCapitalization.words,
            errorText: nameBad ? l10n.treasurySignatoryNameTooLong : null,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.sm),
          EteeloTextInput(
            controller: draft.function,
            label: l10n.treasurySignatoryFunction,
            placeholder: l10n.treasurySignatoryFunctionHint,
            required: true,
            enabled: enabled,
            capitalization: EteeloTextCapitalization.sentence,
            errorText: functionBad
                ? l10n.treasurySignatoryFunctionRequired
                : null,
            onChanged: (_) => onChanged(),
          ),
          if (index == 0)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: draft.filledByCloser,
              onChanged: enabled
                  ? (value) {
                      draft.filledByCloser = value ?? false;
                      onChanged();
                    }
                  : null,
              title: Text(
                l10n.treasurySignatoryCloser,
                style: AppTypography.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
