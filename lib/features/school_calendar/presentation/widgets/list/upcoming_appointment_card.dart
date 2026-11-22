import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar_date_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une carte de « Prochains rendez-vous » : la pastille de date (pleine si
/// l'élément est en cours ou à trois jours au plus), l'intitulé, « Examens ·
/// 2 j », puis « En cours » / « Demain » / « Dans n jours ».
class UpcomingAppointmentCard extends StatelessWidget {
  final CalendarElement element;
  final DateTime today;
  final VoidCallback onTap;

  const UpcomingAppointmentCard({
    super.key,
    required this.element,
    required this.today,
    required this.onTap,
  });

  /// Pleine à trois jours au plus (maquette `filled: now || dd <= 3`).
  static const _strongWithin = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = element.nature.tone;
    final started = !element.startDate.isAfter(today);
    final days = CalendarDays.between(today, element.startDate);
    final length = CalendarDays.between(element.startDate, element.endDate) + 1;
    final title = element.title;
    return EteeloActivatable(
      onActivate: onTap,
      semanticLabel: title,
      builder: (context, highlight) => ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brLg,
            border: Border.all(
              color: highlight.any
                  ? tone.tone
                  : tone.tone.withValues(
                      alpha: AppDimensions.calendarToneBorderOpacity,
                    ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: AppDimensions.calendarCardAccent,
                child: ColoredBox(color: tone.tone),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md - AppSpacing.xs / 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CalendarDateChip(
                      date: element.startDate,
                      tone: tone,
                      strong: started || days <= _strongWithin,
                    ),
                    const SizedBox(width: AppSpacing.md - AppSpacing.xs / 2),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.schoolCalendarItemDays(
                              CalendarLabels.natureShort(l10n, element.nature),
                              length,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            started
                                ? l10n.schoolCalendarWhen('now')
                                : l10n.schoolCalendarDueIn(days),
                            style: AppTypography.labelSmall.copyWith(
                              color: started ? AppColors.terreCuite : tone.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
