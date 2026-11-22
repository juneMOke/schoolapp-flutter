import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « En vigueur » sur le bandeau : savane voilée.
class HeroLivePill extends StatelessWidget {
  final String label;

  const HeroLivePill(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md - AppSpacing.xs / 2,
      vertical: AppSpacing.xs / 2,
    ),
    decoration: BoxDecoration(
      color: AppColors.calendarHeroLiveFill,
      borderRadius: AppRadius.brPill,
      border: Border.all(color: AppColors.calendarHeroLiveBorder),
    ),
    child: Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textOnDark,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// « Ouvrir le calendrier » : pilule blanche, encre bleu profond, chevron.
class HeroOpenButton extends StatelessWidget {
  final VoidCallback onPressed;

  const HeroOpenButton(this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    iconAlignment: IconAlignment.end,
    icon: const Icon(Icons.chevron_right_rounded),
    label: Text(AppLocalizations.of(context)!.schoolCalendarOpen),
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.surfaceRaised,
      foregroundColor: AppColors.bleuProfond,
      minimumSize: const Size(0, AppDimensions.minTouchTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      shape: const StadiumBorder(),
      textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

/// « Publier » sur le bandeau d'un brouillon : pilule voilée, bord clair, à
/// côté de « Ouvrir le calendrier ». Il ouvre la confirmation O5.
class HeroPublishButton extends StatelessWidget {
  final VoidCallback onPressed;

  const HeroPublishButton(this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.campaign_outlined),
    label: Text(AppLocalizations.of(context)!.schoolCalendarPublish),
    style: OutlinedButton.styleFrom(
      backgroundColor: AppColors.calendarBannerVeil,
      foregroundColor: AppColors.textOnDark,
      side: const BorderSide(color: AppColors.calendarBannerVeilBorder),
      minimumSize: const Size(0, AppDimensions.minTouchTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      shape: const StadiumBorder(),
      textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

/// L'avis d'un brouillon sur le bandeau : personne d'autre ne le voit encore.
class HeroDraftNotice extends StatelessWidget {
  final String message;

  const HeroDraftNotice(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.calendarBannerVeil,
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.calendarBannerVeilBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.visibility_off_outlined,
          size: AppDimensions.detailMiniIconSize,
          color: AppColors.calendarBannerIcon,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
        ),
      ],
    ),
  );
}
