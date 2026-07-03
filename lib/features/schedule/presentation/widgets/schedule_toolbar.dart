import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_view_mode.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre supérieure de l'écran (carte surélevée, spec §1) : identité « Mon
/// emploi du temps » à gauche, bascule **Semaine / Jour** à droite. L'app
/// enseignant n'expose que son propre emploi du temps → pas de sélecteur
/// d'enseignant ni d'outil « Démo état ».
class ScheduleToolbar extends StatelessWidget {
  final ScheduleViewMode mode;
  final ValueChanged<ScheduleViewMode> onModeChanged;

  const ScheduleToolbar({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final toggle = SegmentedTabFilter<ScheduleViewMode>(
      selected: mode,
      onSelected: onModeChanged,
      semanticsLabel: l10n.scheduleViewToggleSemantics,
      options: [
        SegmentedTabOption(
          label: l10n.scheduleViewWeek,
          value: ScheduleViewMode.week,
          icon: Icons.calendar_view_week_rounded,
        ),
        SegmentedTabOption(
          label: l10n.scheduleViewDay,
          value: ScheduleViewMode.day,
          icon: Icons.view_day_rounded,
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = _Identity(l10n: l10n);
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerLeft, child: toggle),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.gridGap),
              toggle,
            ],
          );
        },
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final AppLocalizations l10n;

  const _Identity({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.bleuArdoiseSoft,
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.bleuArdoise,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scheduleEyebrow.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.scheduleTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.bleuArdoise,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
