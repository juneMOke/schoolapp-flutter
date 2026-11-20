import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_time_format.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_day_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un créneau libre de la journée d'un brouillon : l'heure, puis une cible en
/// tirets « + Créneau libre », comme une case libre de la grille (I8).
class ScheduleFreeSlotRow extends StatelessWidget {
  final TimeSlot slot;
  final VoidCallback? onTap;

  const ScheduleFreeSlotRow({super.key, required this.slot, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final range =
        '${ScheduleTimeFormat.hourMinute(slot.startTime)} – '
        '${ScheduleTimeFormat.hourMinute(slot.endTime)}';
    return Semantics(
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      label: '$range · ${l10n.classTimetableFreeSlot}',
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.stateHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              ScheduleDayTimeColumn(slot: slot),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: EteeloDashedContainer(
                  backgroundColor: AppColors.surfaceRaised,
                  borderColor: AppColors.terreCuite,
                  borderRadius: AppRadius.brSm,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: AppColors.terreCuite),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          l10n.classTimetableFreeSlot,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.terreCuite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
