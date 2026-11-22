import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux réglages de la simulation : le critère, **en lecture** — il se
/// choisit plus haut, en E, et « Changer » y remonte (I14) — puis le seuil
/// « ingérable » (I15).
class RecoverySimulationControls extends StatelessWidget {
  final String criterionLabel;
  final int unmanageableBelow;
  final ValueChanged<int> onUnmanageableChanged;
  final VoidCallback onChangeRule;

  const RecoverySimulationControls({
    super.key,
    required this.criterionLabel,
    required this.unmanageableBelow,
    required this.onUnmanageableChanged,
    required this.onChangeRule,
  });

  static final _caps = AppTypography.labelSmall.copyWith(
    color: AppColors.textMuted,
    letterSpacing: AppTypography.capsLetterSpacing,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.gridGap,
      runSpacing: AppSpacing.gridGap,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recoverySimulationCriterionHeading.toUpperCase(),
              style: _caps,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CriterionChip(label: criterionLabel),
                Semantics(
                  label: l10n.recoverySimulationChangeA11y,
                  excludeSemantics: true,
                  button: true,
                  child: TextButton.icon(
                    onPressed: onChangeRule,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.bleuArdoise,
                      minimumSize: const Size(
                        AppDimensions.minTouchTarget,
                        AppDimensions.minTouchTarget,
                      ),
                      textStyle: AppTypography.labelLarge,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_up,
                      size: AppDimensions.recoverySimChipIcon,
                    ),
                    label: Text(l10n.recoverySimulationChange),
                  ),
                ),
              ],
            ),
          ],
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.recoverySimSliderMaxWidth,
          ),
          child: _UnmanageableSlider(
            percent: unmanageableBelow,
            onChanged: onUnmanageableChanged,
            caps: _caps,
          ),
        ),
      ],
    );
  }
}

class _CriterionChip extends StatelessWidget {
  final String label;

  const _CriterionChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.feeStatusDueSoft,
      borderRadius: AppRadius.brPill,
      border: Border.all(
        color: ColorMix.tint(AppColors.border, AppColors.error, 12),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.person_remove_outlined,
          size: AppDimensions.recoverySimChipIcon,
          color: AppColors.error,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}

/// « Classe ingérable sous **60 %** de l'effectif » : la valeur vit dans le
/// libellé, pas dans une bulle qui disparaît au relâcher.
class _UnmanageableSlider extends StatelessWidget {
  final int percent;
  final ValueChanged<int> onChanged;
  final TextStyle caps;

  const _UnmanageableSlider({
    required this.percent,
    required this.onChanged,
    required this.caps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const min = AppConstants.recoveryUnmanageableMin;
    const max = AppConstants.recoveryUnmanageableMax;
    const step = AppConstants.recoveryUnmanageableStep;
    final value = l10n.recoverySimulationPercent(percent);
    final sentence = l10n.recoverySimulationUnmanageableSlider(value);
    final at = sentence.indexOf(value);
    final upper = caps.copyWith(color: AppColors.textMuted);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text.rich(
            at < 0
                ? TextSpan(text: sentence.toUpperCase())
                : TextSpan(
                    children: [
                      TextSpan(text: sentence.substring(0, at).toUpperCase()),
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: sentence
                            .substring(at + value.length)
                            .toUpperCase(),
                      ),
                    ],
                  ),
            style: upper,
          ),
        ),
        Slider(
          value: percent.clamp(min, max).toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) ~/ step,
          semanticFormatterCallback: (_) => sentence,
          activeColor: AppColors.terreCuite,
          onChanged: (v) {
            final next = v.round();
            if (next != percent) onChanged(next);
          },
        ),
      ],
    );
  }
}
