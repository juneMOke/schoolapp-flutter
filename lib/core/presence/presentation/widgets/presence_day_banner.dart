import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_banner_parts.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_progress_ring.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau d'un registre du jour : navigation de jour, horaire, progression
/// et actions (restants présents, valider). La date ouvre le calendrier quand
/// [onPickDay] est fourni. Les actions disparaissent quand
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

  /// `null` : pas de calendrier, la date se lit seulement.
  final VoidCallback? onPickDay;

  /// `null` : le compte ne règle pas l'horaire — la pastille le montre, sans
  /// rien ouvrir.
  final VoidCallback? onSettings;

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
    this.onPickDay,
    this.onSettings,
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
              // Flexible : sur téléphone la date longue passe à la ligne
              // plutôt que de pousser le bouton « jour suivant » hors du
              // bandeau.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.presenceMarkOnBannerMuted,
                      ),
                    ),
                    PresenceBannerDay(day: day, onPick: onPickDay),
                    const SizedBox(height: AppSpacing.xs),
                    PresenceSchedulePill(schedule: schedule, onTap: onSettings),
                  ],
                ),
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
          // La progression et ses actions restent voisines ; sur un écran
          // étroit les actions passent sous la progression au lieu de
          // déborder.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PresenceProgressRing(marked: marked, total: total),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.presenceMarkProgress(marked, total),
                          style: AppTypography.titleMedium.copyWith(
                            color: onBanner,
                          ),
                        ),
                        Text(
                          detail,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.presenceMarkOnBannerMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showActions)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PresenceBannerButton(
                      icon: Icons.checklist,
                      tooltip: l10n.presenceMarkMarkRemaining,
                      onPressed: onMarkRemaining,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: EteeloButton.primary(
                        label: validateLabel,
                        icon: Icons.task_alt,
                        onPressed: onValidate,
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
