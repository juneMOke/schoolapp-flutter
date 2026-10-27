import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un bouton d'icône posé sur le bandeau sombre (jour précédent, restants
/// présents).
class PresenceBannerButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const PresenceBannerButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppDimensions.presenceMarkTapTarget,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: AppColors.presenceMarkOnBanner,
      disabledColor: AppColors.presenceMarkOnBannerFaint,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        side: const BorderSide(color: AppColors.presenceMarkOnBannerMuted),
      ),
    ),
  );
}

/// La date longue du bandeau. Avec [onPick], elle ouvre le calendrier : une
/// icône le dit, et la zone d'appui fait 48 dp.
class PresenceBannerDay extends StatelessWidget {
  /// `YYYY-MM-DD`.
  final String day;
  final VoidCallback? onPick;

  const PresenceBannerDay({super.key, required this.day, this.onPick});

  @override
  Widget build(BuildContext context) {
    final onPick = this.onPick;
    final label = Text(
      PresenceLabels.longDay(MaterialLocalizations.of(context), day),
      style: AppTypography.titleLarge.copyWith(
        color: AppColors.presenceMarkOnBanner,
      ),
    );
    if (onPick == null) return label;
    return Tooltip(
      message: AppLocalizations.of(context)!.presenceMarkPickDay,
      child: InkWell(
        onTap: onPick,
        borderRadius: AppRadius.brSm,
        child: TouchTarget(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: label),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.calendar_month_outlined,
                size: AppSpacing.xl,
                color: AppColors.presenceMarkOnBannerMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// L'horaire du jour, en pastille. Avec [onTap], elle ouvre les réglages ;
/// sans, elle se lit seulement.
class PresenceSchedulePill extends StatelessWidget {
  final PresenceSchedule schedule;
  final VoidCallback? onTap;

  const PresenceSchedulePill({super.key, required this.schedule, this.onTap});

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    final pill = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.presenceMarkOnBannerMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            // Le réglage s'ouvre (tune) ou se lit seulement (horloge).
            onTap == null ? Icons.schedule : Icons.tune,
            size: AppSpacing.lg,
            color: AppColors.presenceMarkOnBanner,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.presenceMarkSettingsPill(
                schedule.start.wire,
                schedule.toleranceMinutes,
              ),
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.presenceMarkOnBanner,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brPill,
      // La pastille reste fine ; sa zone d'appui fait 48 dp.
      child: TouchTarget(child: pill),
    );
  }
}
