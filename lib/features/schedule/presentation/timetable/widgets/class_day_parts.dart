import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_time_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_day_session.dart';

export 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_day_selector.dart';

/// Un créneau de la journée d'une classe (EDT §4.6 E) : l'heure, le liseré du
/// domaine, puis la séance — ou « Pas de cours ».
class ClassDayRow extends StatelessWidget {
  final TimeSlot slot;
  final TimetableCell? cell;
  final AcademicsClassVisual? tone;
  final String? domain;
  final bool compact;
  final bool now;
  final bool dimmed;
  final VoidCallback? onOpen;

  const ClassDayRow({
    super.key,
    required this.slot,
    required this.cell,
    required this.tone,
    required this.domain,
    required this.compact,
    this.now = false,
    this.dimmed = false,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cell = this.cell;
    final tone = this.tone;
    final mono = AppTextStyles.codeMuted;
    return Opacity(
      opacity: dimmed ? AppDimensions.timetableDimmedOpacity : 1,
      child: ColoredBox(
        color: now ? AppColors.timetableWarmSurface : AppColors.surfaceRaised,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: AppDimensions.timetableDayTimeWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ScheduleTimeFormat.hourMinute(slot.startTime),
                        style: mono.copyWith(
                          color: now
                              ? AppColors.terreCuite
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ScheduleTimeFormat.hourMinute(slot.endTime),
                        style: mono.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: AppDimensions.timetableGridTodayBar,
                  decoration: BoxDecoration(
                    color: tone?.accent ?? AppColors.border,
                    borderRadius: AppRadius.brPill,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: cell == null || tone == null
                      ? _Empty(label: l10n.classTimetableDayNoClass)
                      : ClassDaySession(
                          start: ScheduleTimeFormat.hourMinute(slot.startTime),
                          cell: cell,
                          tone: tone,
                          domain: domain,
                          compact: compact,
                          now: now,
                          onOpen: onOpen,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String label;

  const _Empty({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    decoration: BoxDecoration(
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      label,
      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
    ),
  );
}

/// La récréation, intercalée dans la journée : bande ambre en capitales.
class ClassDayBreak extends StatelessWidget {
  final String label;

  const ClassDayBreak({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: const BoxDecoration(
      color: AppColors.timetableHintSurface,
      border: Border(
        top: BorderSide(color: AppColors.border),
        bottom: BorderSide(color: AppColors.border),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.free_breakfast_outlined,
          size: AppSpacing.md,
          color: AppColors.timetableHintInk,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.timetableHintInk,
              fontWeight: FontWeight.w600,
              letterSpacing: AppDimensions.insPaveLabelLetterSpacing,
            ),
          ),
        ),
      ],
    ),
  );
}
