import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/elements/calendar_element_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La liste du mois ou du jour touché (spec §4.6 E, maquette `CalMonthSide`) :
/// en-tête terre cuite pâle avec son médaillon, « Juin 2026 » (ou le jour) et
/// le compteur, « Tout le mois » quand un jour est touché ; une ligne par
/// élément, les périodes comprises ; en pied, « Ajouter un événement » ou
/// « Ajouter le 9 juin », pleine largeur.
class CalendarMonthSide extends StatelessWidget {
  final DateTime month;
  final DateTime? day;
  final List<CalendarElement> elements;
  final Map<String, SchoolEventRecord> records;
  final CalendarScopeOptions scopes;
  final DateTime today;
  final bool canWrite;
  final ValueChanged<CalendarElement> onOpen;
  final ValueChanged<DateTime?> onAdd;
  final VoidCallback onClearDay;

  const CalendarMonthSide({
    super.key,
    required this.month,
    required this.day,
    required this.elements,
    required this.records,
    required this.scopes,
    required this.today,
    required this.canWrite,
    required this.onOpen,
    required this.onAdd,
    required this.onClearDay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final first = day ?? month;
    final sorted = [...elements]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final now = CalendarDays.of(today);
    final raw = MaterialLocalizations.of(context).formatMonthYear(month);
    final title = day == null
        ? '${raw[0].toUpperCase()}${raw.substring(1)}'
        : CalendarLabels.weekdayDay(context, day!);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.calendarUpcomingBorder),
        boxShadow: AppElevation.shadowKpi,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: title,
              count: sorted.length,
              onClearDay: day == null ? null : onClearDay,
            ),
            for (final e in sorted)
              CalendarSideRow(
                element: e,
                record: records[e.id],
                scopes: scopes,
                chipDate: e.startDate.isBefore(first) ? first : e.startDate,
                current: e.covers(now),
                onTap: () => onOpen(e),
              ),
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.all(
                  AppSpacing.md + AppSpacing.xs / 2,
                ),
                child: Text(
                  day == null
                      ? l10n.schoolCalendarNothingThisMonth
                      : l10n.schoolCalendarNothingThisDay,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            if (canWrite)
              Container(
                padding: const EdgeInsets.all(
                  AppSpacing.sm + AppSpacing.xs / 2,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: EteeloButton.secondary(
                  label: day == null
                      ? l10n.schoolCalendarAddEvent
                      : l10n.schoolCalendarAddOn(
                          CalendarLabels.shortDay(context, day!),
                        ),
                  icon: Icons.add_rounded,
                  size: EteeloButtonSize.regular,
                  onPressed: () => onAdd(day ?? month),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onClearDay;

  const _Header({
    required this.title,
    required this.count,
    required this.onClearDay,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md + AppSpacing.xs / 2,
      vertical: AppSpacing.md,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.calendarNowSoft, AppColors.calendarUpcomingMid],
      ),
      border: Border(
        bottom: BorderSide(color: AppColors.calendarUpcomingBorder),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: AppDimensions.calendarSideMedallion,
          height: AppDimensions.calendarSideMedallion,
          decoration: const BoxDecoration(
            color: AppColors.terreCuite,
            borderRadius: AppRadius.brSm,
          ),
          child: const Icon(
            Icons.format_list_bulleted_rounded,
            size: AppDimensions.calendarSideMedallionIcon,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.bleuProfond,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: const BoxDecoration(
            color: AppColors.terreCuite,
            borderRadius: AppRadius.brPill,
          ),
          child: Text(
            '$count',
            style: AppTypography.calendarCount.copyWith(
              color: AppColors.textOnDark,
              fontSize: AppTypography.labelSmall.fontSize,
            ),
          ),
        ),
        if (onClearDay case final clear?) ...[
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: clear,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
              shape: const StadiumBorder(),
              backgroundColor: AppColors.surfaceRaised,
              foregroundColor: AppColors.bleuArdoise,
              side: const BorderSide(color: AppColors.calendarUpcomingBorder),
            ),
            child: Text(AppLocalizations.of(context)!.schoolCalendarWholeMonth),
          ),
        ],
      ],
    ),
  );
}
