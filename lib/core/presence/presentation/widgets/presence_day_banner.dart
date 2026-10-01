import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_progress_ring.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau d'un registre du jour : navigation de jour, horaire, progression
/// et actions (restants présents, valider). Les actions disparaissent quand
/// [showActions] est faux — jour validé, ou compte sans droit d'écriture.
class PresenceDayBanner extends StatelessWidget {
  /// « Registre du jour », « Appel du jour · 6e A »…
  final String eyebrow;

  /// `YYYY-MM-DD`.
  final String day;
  final bool isToday;
  final PresenceSchedule schedule;
  final int marked;
  final int total;

  /// La ligne sous la progression (« 12 à pointer · 3 sur la tablette »).
  final String detail;

  final bool showActions;
  final String validateLabel;

  /// `null` : début de l'année scolaire, pas de jour précédent.
  final VoidCallback? onPrevious;

  /// `null` : aujourd'hui, pas de jour suivant.
  final VoidCallback? onNext;
  final VoidCallback onToday;
  final VoidCallback onSettings;

  /// `null` : personne à marquer.
  final VoidCallback? onMarkRemaining;

  /// `null` : rien à valider.
  final VoidCallback? onValidate;

  const PresenceDayBanner({
    super.key,
    required this.eyebrow,
    required this.day,
    required this.isToday,
    required this.schedule,
    required this.marked,
    required this.total,
    required this.detail,
    required this.showActions,
    required this.validateLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onSettings,
    required this.onMarkRemaining,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const onBanner = AppColors.presenceMarkOnBanner;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.brCard,
        gradient: LinearGradient(
          colors: [
            AppColors.presenceMarkBannerStart,
            AppColors.presenceMarkBannerMid,
            AppColors.presenceMarkBannerEnd,
          ],
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PresenceBannerButton(
                icon: Icons.chevron_left,
                tooltip: l10n.presenceMarkPreviousDay,
                onPressed: onPrevious,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.presenceMarkOnBannerMuted,
                    ),
                  ),
                  Text(
                    PresenceLabels.longDay(
                      MaterialLocalizations.of(context),
                      day,
                    ),
                    style: AppTypography.titleLarge.copyWith(color: onBanner),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SchedulePill(schedule: schedule, onTap: onSettings),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              PresenceBannerButton(
                icon: Icons.chevron_right,
                tooltip: l10n.presenceMarkNextDay,
                onPressed: onNext,
              ),
              if (!isToday) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: onToday,
                  style: TextButton.styleFrom(foregroundColor: onBanner),
                  child: Text(l10n.presenceMarkGoToday),
                ),
              ],
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PresenceProgressRing(marked: marked, total: total),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.presenceMarkProgress(marked, total),
                    style: AppTypography.titleMedium.copyWith(color: onBanner),
                  ),
                  Text(
                    detail,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.presenceMarkOnBannerMuted,
                    ),
                  ),
                ],
              ),
              if (showActions) ...[
                const SizedBox(width: AppSpacing.md),
                PresenceBannerButton(
                  icon: Icons.checklist,
                  tooltip: l10n.presenceMarkMarkRemaining,
                  onPressed: onMarkRemaining,
                ),
                const SizedBox(width: AppSpacing.sm),
                EteeloButton.primary(
                  label: validateLabel,
                  icon: Icons.task_alt,
                  onPressed: onValidate,
                  fullWidth: false,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

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

class _SchedulePill extends StatelessWidget {
  final PresenceSchedule schedule;
  final VoidCallback onTap;

  const _SchedulePill({required this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadius.brPill,
    child: Container(
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
          const Icon(
            Icons.tune,
            size: AppSpacing.lg,
            color: AppColors.presenceMarkOnBanner,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppLocalizations.of(context)!.presenceMarkSettingsPill(
              schedule.start.wire,
              schedule.toleranceMinutes,
            ),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.presenceMarkOnBanner,
            ),
          ),
        ],
      ),
    ),
  );
}
