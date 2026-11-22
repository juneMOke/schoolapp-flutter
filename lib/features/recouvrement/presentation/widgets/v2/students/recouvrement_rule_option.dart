import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recouvrement_rule_amount_field.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recouvrement_rule_effect.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un choix de [RecouvrementRuleChoice] (`RecRuleSelect`) : le rond radio, le
/// libellé, le champ de montant pour « a payé au moins », puis la jauge et
/// « {n} en ordre » — ou la raison de son indisponibilité.
class RecouvrementRuleOption extends StatelessWidget {
  final RecoveryRuleKind rule;
  final String label;
  final bool checked;
  final bool enabled;
  final bool narrow;

  /// `null` : pas de réponse honnête (montant vide, mixte).
  final int? count;
  final bool awaitingAmount;
  final int studentCount;
  final FocusNode focusNode;
  final KeyEventResult Function(KeyEvent event) onKey;
  final VoidCallback onSelected;
  final int? thresholdInCents;
  final String? currency;
  final ValueChanged<int?> onThresholdChanged;

  const RecouvrementRuleOption({
    super.key,
    required this.rule,
    required this.label,
    required this.checked,
    required this.enabled,
    required this.narrow,
    required this.count,
    required this.awaitingAmount,
    required this.studentCount,
    required this.focusNode,
    required this.onKey,
    required this.onSelected,
    required this.thresholdInCents,
    required this.currency,
    required this.onThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final withField = rule == RecoveryRuleKind.atLeast && enabled;
    final ink = checked ? AppColors.bleuProfond : AppColors.textSecondary;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            if (withField)
              RecouvrementRuleAmountField(
                thresholdInCents: thresholdInCents,
                currency: currency,
                onFocused: onSelected,
                onChanged: onThresholdChanged,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (!enabled)
          Text(
            l10n.recouvrementAtLeastMixed,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          )
        else
          RecoveryRuleEffect(
            count: count,
            awaitingAmount: awaitingAmount,
            total: studentCount,
          ),
      ],
    );
    final card = AnimatedContainer(
      duration: AppMotion.medium,
      constraints: const BoxConstraints(
        minHeight: AppDimensions.minTouchTarget,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppDimensions.recoverySpace11,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        color: checked
            ? AppColors.surfaceRaised
            : narrow
            ? AppColors.surfaceRaised.withValues(alpha: 0.6)
            : null,
        border: narrow || checked
            ? Border.all(
                color: checked ? AppColors.bleuProfond : AppColors.border,
                width: AppDimensions.recoveryControlBorderWidth,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.recoverySpace2),
            child: RecoveryRuleRadio(checked: checked),
          ),
          const SizedBox(width: AppDimensions.recoverySpace10),
          Expanded(child: body),
        ],
      ),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: checked,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Focus(
          focusNode: focusNode,
          canRequestFocus: enabled,
          skipTraversal: !enabled,
          onKeyEvent: (_, event) => onKey(event),
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasPrimaryFocus;
              return MouseRegion(
                cursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.forbidden,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled
                      ? () {
                          focusNode.requestFocus();
                          onSelected();
                        }
                      : null,
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.brMd,
                      border: focused
                          ? Border.all(
                              color: AppColors.bleuArdoise,
                              width: AppDimensions.focusRingWidth,
                            )
                          : null,
                    ),
                    child: card,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
