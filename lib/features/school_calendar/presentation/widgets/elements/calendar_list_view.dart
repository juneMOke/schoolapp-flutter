import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/elements/calendar_list_row.dart';

/// La vue Liste (spec §4.3, maquette `CalListView`) : tous les éléments, les
/// périodes comprises, groupés par mois dans l'ordre des dates — une carte
/// par mois sous son en-tête « SEPTEMBRE 2025 » et son compteur.
class CalendarListView extends StatelessWidget {
  final List<CalendarElement> elements;
  final Map<String, SchoolEventRecord> records;
  final CalendarScopeOptions scopes;
  final DateTime today;
  final bool compact;
  final ValueChanged<CalendarElement> onOpen;

  const CalendarListView({
    super.key,
    required this.elements,
    required this.records,
    required this.scopes,
    required this.today,
    required this.compact,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...elements]
      ..sort((a, b) {
        final byStart = a.startDate.compareTo(b.startDate);
        if (byStart != 0) return byStart;
        final byNature = DaysBetween.order
            .indexOf(a.nature)
            .compareTo(DaysBetween.order.indexOf(b.nature));
        return byNature != 0 ? byNature : a.id.compareTo(b.id);
      });
    final groups = <DateTime, List<CalendarElement>>{};
    for (final e in sorted) {
      final key = DateTime.utc(e.startDate.year, e.startDate.month);
      (groups[key] ??= []).add(e);
    }
    final dates = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (g, MapEntry(key: month, value: list))
            in groups.entries.indexed) ...[
          if (g > 0) const SizedBox(height: AppSpacing.md + AppSpacing.xs / 2),
          _MonthHeader(
            label: dates.formatMonthYear(month).toUpperCase(),
            count: list.length,
          ),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: AppColors.calendarListBorder),
              boxShadow: AppElevation.shadowKpi,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.brLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, e) in list.indexed)
                    CalendarListRow(
                      element: e,
                      record: records[e.id],
                      scopes: scopes,
                      today: today,
                      alternate: i.isOdd,
                      first: i == 0,
                      compact: compact,
                      onTap: () => onOpen(e),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;
  final int count;

  const _MonthHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    child: Row(
      children: [
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            fontSize: AppTypography.labelMedium.fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.calendarListMonthInk,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs + AppSpacing.xs / 2,
          ),
          decoration: const BoxDecoration(
            color: AppColors.calendarCountSoft,
            borderRadius: AppRadius.brPill,
          ),
          child: Text(
            '$count',
            style: AppTypography.calendarCount.copyWith(
              color: AppColors.calendarCountInk,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: AppDimensions.calendarHairline,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.calendarUpcomingBorder, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
