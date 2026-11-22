import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête du bloc D (`FinSectionHead`) : médaillon, titre, sous-titre, le
/// choix du frais à droite (dessous quand [stacked]), puis un filet dégradé.
class RecoveryClassPanelHead extends StatelessWidget {
  final Widget? action;
  final bool stacked;

  const RecoveryClassPanelHead({super.key, this.action, required this.stacked});

  static const _tone = AppColors.bleuArdoise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final action = this.action;
    final heading = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppDimensions.recoveryClassHeadMedallion,
          height: AppDimensions.recoveryClassHeadMedallion,
          decoration: BoxDecoration(
            color: ColorMix.tint(AppColors.surfaceRaised, _tone, 11),
            borderRadius: BorderRadius.circular(
              AppDimensions.recoveryClassHeadMedallionRadius,
            ),
            border: Border.all(
              color: ColorMix.tint(AppColors.surfaceRaised, _tone, 20),
            ),
          ),
          child: const Icon(
            Icons.school_outlined,
            size: AppDimensions.recoveryClassHeadIconSize,
            color: _tone,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recoveryClassesTitle,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.recoverySpace2),
                Text(
                  l10n.recoveryClassesSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gridGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (action == null)
            heading
          else if (stacked) ...[
            heading,
            const SizedBox(height: AppSpacing.md),
            Align(alignment: AlignmentDirectional.centerStart, child: action),
          ] else
            Row(
              children: [
                Expanded(flex: 3, child: heading),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: action,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _tone.withValues(alpha: 0.38),
                  _tone.withValues(alpha: 0.04),
                  _tone.withValues(alpha: 0),
                ],
                stops: const [0, 0.62, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La pastille d'un frais seul (`FinDevChip` taille lg) : le symbole de sa
/// devise en gras, puis son libellé, aux couleurs de la devise.
class RecoveryFeeCurrencyChip extends StatelessWidget {
  final String label;
  final String currency;

  const RecoveryFeeCurrencyChip({
    super.key,
    required this.label,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final usd = currency == 'USD';
    final ink = usd ? AppColors.treasuryUsdInk : AppColors.treasuryCdfInk;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.recoverySpace11,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: usd ? AppColors.treasuryUsdSoft : AppColors.treasuryCdfSoft,
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: usd
              ? AppColors.treasuryUsdBorder
              : AppColors.treasuryCdfBorder,
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: MoneyFormat.symbolOf(currency),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' $label'),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelLarge.copyWith(color: ink),
      ),
    );
  }
}
