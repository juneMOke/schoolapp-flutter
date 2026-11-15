import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_amount_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La question de la clôture et ses deux grandes réponses (sémantique radio).
class ClosingAnswerPicker extends StatelessWidget {
  final String shownExpected;
  final ClosingAnswer? answer;
  final bool enabled;
  final ValueChanged<ClosingAnswer> onChanged;

  const ClosingAnswerPicker({
    super.key,
    required this.shownExpected,
    required this.answer,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.treasuryCloseQuestion(shownExpected),
          style: AppTypography.titleMedium,
        ),
        Text(
          l10n.treasuryCloseQuestionHint,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _AnswerTile(
              icon: Icons.check,
              title: l10n.treasuryAnswerYes,
              hint: l10n.treasuryAnswerYesHint,
              ink: AppColors.success,
              selected: answer == ClosingAnswer.matches,
              onTap: enabled ? () => onChanged(ClosingAnswer.matches) : null,
            ),
            _AnswerTile(
              icon: Icons.close,
              title: l10n.treasuryAnswerNo,
              hint: l10n.treasuryAnswerNoHint,
              ink: AppColors.error,
              selected: answer == ClosingAnswer.differs,
              onTap: enabled ? () => onChanged(ClosingAnswer.differs) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final Color ink;
  final bool selected;
  final VoidCallback? onTap;

  const _AnswerTile({
    required this.icon,
    required this.title,
    required this.hint,
    required this.ink,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: AppDimensions.treasuryFigureMinWidth * 1.5,
      minHeight: AppDimensions.minTouchTarget,
    ),
    child: Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? ink.withValues(alpha: 0.1) : AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(color: selected ? ink : AppColors.border, width: 2),
        ),
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: ink),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AppTypography.titleSmall),
                      Text(
                        hint,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// La réponse « Non » : ce qu'il y a vraiment, l'écart en direct, et sa
/// justification obligatoire (R9, R16).
class ClosingDifference extends StatelessWidget {
  final TreasuryCurrency currency;
  final int shownExpectedInCents;
  final TextEditingController declared;
  final TextEditingController justification;
  final bool enabled;
  final bool showErrors;
  final VoidCallback onChanged;
  final VoidCallback onPickYes;

  const ClosingDifference({
    super.key,
    required this.currency,
    required this.shownExpectedInCents,
    required this.declared,
    required this.justification,
    required this.enabled,
    required this.showErrors,
    required this.onChanged,
    required this.onPickYes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cents = TreasuryAmountField.read(declared.text, currency);
    final gap = cents == null
        ? null
        : CashClosingRules.gapOf(
            shownExpectedInCents: shownExpectedInCents,
            declared: cents,
          );
    final tooShort =
        showErrors &&
        justification.text.trim().length <
            CashClosingRules.minJustificationLength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TreasuryAmountField(
          controller: declared,
          label: l10n.treasuryDeclaredQuestion,
          currency: currency,
          enabled: enabled,
          showError: showErrors,
          onChanged: (_) => onChanged(),
        ),
        if (gap != null) ...[
          const SizedBox(height: AppSpacing.sm),
          if (gap == 0)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.treasuryNoGap,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onPickYes,
                  child: Text(l10n.treasuryPickYes),
                ),
              ],
            )
          else
            Text(
              gap < 0
                  ? l10n.treasuryGapMissingBanner(
                      TreasuryFormat.signedMoney(gap, currency),
                      TreasuryFormat.money(-gap, currency),
                    )
                  : l10n.treasuryGapSurplusBanner(
                      TreasuryFormat.signedMoney(gap, currency),
                      TreasuryFormat.money(gap, currency),
                    ),
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        EteeloTextInput(
          controller: justification,
          label: l10n.treasuryGapReason,
          placeholder: l10n.treasuryGapReasonHint,
          keyboardType: EteeloTextInputType.multiline,
          minLines: 2,
          maxLines: 3,
          required: true,
          enabled: enabled,
          errorText: tooShort ? l10n.treasuryGapReasonShort : null,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final suggestion in [
              l10n.treasuryGapSuggest1,
              l10n.treasuryGapSuggest2,
            ])
              ActionChip(
                label: Text(suggestion),
                // Une suggestion de justification s'ajoute au texte (§14 bis).
                onPressed: enabled
                    ? () {
                        final current = justification.text.trim();
                        justification.text = current.isEmpty
                            ? suggestion
                            : '$current ; $suggestion';
                        onChanged();
                      }
                    : null,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.treasuryGapReasonVisible,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
