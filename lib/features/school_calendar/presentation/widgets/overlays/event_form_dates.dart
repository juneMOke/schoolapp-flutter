import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Du » et « Au (inclus) » dans un bloc teinté de la nature, la durée
/// dessous (maquette CalEditModal).
class EventDatesBlock extends StatelessWidget {
  final CalendarNature nature;
  final DateTime? start;
  final DateTime? end;
  final DateTime yearStart;
  final DateTime yearEnd;
  final ValueChanged<DateTime?> onStart;
  final ValueChanged<DateTime?> onEnd;

  const EventDatesBlock({
    super.key,
    required this.nature,
    required this.start,
    required this.end,
    required this.yearStart,
    required this.yearEnd,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = nature.tone;
    final from = start;
    final to = end;
    final valid = from != null && to != null && !to.isBefore(from);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.soft, AppColors.surfaceRaised],
        ),
        border: Border.all(color: tone.tone.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EventDatesRow(
            start: start,
            end: end,
            yearStart: yearStart,
            yearEnd: yearEnd,
            onStart: onStart,
            onEnd: onEnd,
          ),
          if (valid) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.date_range_outlined, size: 13, color: tone.ink),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${l10n.schoolCalendarDurationDays(CalendarDays.between(from, to) + 1)}'
                    ' · ${CalendarLabels.range(context, from, to)}',
                    style: AppTypography.labelSmall.copyWith(color: tone.ink),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// « Du » et « Au (inclus) », côte à côte dès que la rangée laisse 164 dp à
/// chacune (`AppBreakpoints.datePairSideBySideMin`), l'un sous l'autre en
/// deçà. Les dates rendues sont des jours civils.
class EventDatesRow extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;
  final DateTime yearStart;
  final DateTime yearEnd;
  final ValueChanged<DateTime?> onStart;
  final ValueChanged<DateTime?> onEnd;

  const EventDatesRow({
    super.key,
    required this.start,
    required this.end,
    required this.yearStart,
    required this.yearEnd,
    required this.onStart,
    required this.onEnd,
  });

  static DateTime? _day(DateTime? d) =>
      d == null ? null : DateTime.utc(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final from = EteeloDateInput(
      label: l10n.schoolCalendarFormFrom,
      value: start,
      required: true,
      firstDate: yearStart,
      lastDate: yearEnd,
      onChanged: (d) => onStart(_day(d)),
    );
    final to = EteeloDateInput(
      label: l10n.schoolCalendarFormTo,
      value: end,
      required: true,
      firstDate: yearStart,
      lastDate: yearEnd,
      onChanged: (d) => onEnd(_day(d)),
    );
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= AppBreakpoints.datePairSideBySideMin
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: from),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: to),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                from,
                const SizedBox(height: AppSpacing.md),
                to,
              ],
            ),
    );
  }
}
