import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/components/status/pending_sync_badge.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/school_calendar_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar_date_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une liste d'éléments (spec §4.6 E) : la liste du mois ou du jour touché, et
/// la vue Liste groupée par mois. Une ligne par élément : la pastille de date,
/// l'intitulé, le cadenas ou l'envoi en attente, les dates et la portée.
class CalendarElementList extends StatelessWidget {
  final List<CalendarElement> elements;
  final Map<String, SchoolEventRecord> records;
  final CalendarScopeOptions scopes;
  final DateTime today;
  final String emptyLabel;
  final ValueChanged<CalendarElement> onOpen;

  /// Regroupe par mois (vue Liste).
  final bool groupByMonth;

  const CalendarElementList({
    super.key,
    required this.elements,
    required this.records,
    required this.scopes,
    required this.today,
    required this.emptyLabel,
    required this.onOpen,
    this.groupByMonth = false,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...elements]
      ..sort((a, b) {
        final byStart = a.startDate.compareTo(b.startDate);
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });
    if (sorted.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          emptyLabel,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    final dates = MaterialLocalizations.of(context);
    final children = <Widget>[];
    DateTime? month;
    for (final element in sorted) {
      final start = element.startDate;
      if (groupByMonth &&
          (month == null ||
              month.year != start.year ||
              month.month != start.month)) {
        month = DateTime.utc(start.year, start.month);
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.md,
              0,
              AppSpacing.xs,
            ),
            child: Text(
              dates.formatMonthYear(month),
              style: AppTypography.titleSmall,
            ),
          ),
        );
      }
      children.add(
        _ElementRow(
          element: element,
          record: records[element.id],
          scopes: scopes,
          past: element.endDate.isBefore(today),
          current: element.covers(today),
          onTap: () => onOpen(element),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _ElementRow extends StatelessWidget {
  final CalendarElement element;
  final SchoolEventRecord? record;
  final CalendarScopeOptions scopes;
  final bool past;
  final bool current;
  final VoidCallback onTap;

  const _ElementRow({
    required this.element,
    required this.record,
    required this.scopes,
    required this.past,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = element.nature.tone;
    final rejected = record?.isRejected ?? false;
    return Opacity(
      opacity: past ? AppDimensions.calendarPastOpacity : 1,
      child: EteeloActivatable(
        onActivate: onTap,
        semanticLabel:
            '${element.title}, ${CalendarLabels.dates(context, element)}',
        builder: (context, highlight) => TouchTarget(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: highlight.any ? tone.soft : AppColors.surfaceRaised,
              borderRadius: AppRadius.brSm,
              border: Border.all(
                color: rejected ? AppColors.error : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                CalendarDateChip(
                  date: element.startDate,
                  tone: tone,
                  strong: current,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        element.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium,
                      ),
                      Text(
                        [
                          CalendarLabels.dates(context, element),
                          CalendarLabels.scope(l10n, element.scope, scopes),
                          if (element.toVerify) l10n.schoolCalendarToVerify,
                        ].join(' · '),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (rejected)
                        Text(
                          l10n.schoolCalendarRejected(
                            CalendarLabels.refusalCode(l10n, record?.errorCode),
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ),
                if (element.isNational)
                  const Icon(
                    SchoolCalendarTones.nationalIcon,
                    size: AppSpacing.lg,
                    color: AppColors.textSecondary,
                  )
                else if (record?.isPending ?? false)
                  const PendingSyncBadge(),
                const Icon(
                  Icons.visibility_outlined,
                  size: AppSpacing.lg,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
