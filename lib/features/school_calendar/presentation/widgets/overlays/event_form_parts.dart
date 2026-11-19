import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_event_validation.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Du » et « Au (inclus) », côte à côte dès `formGridTwoColMin` de carte,
/// l'un sous l'autre en deçà (spec §4.4 O2). Les dates rendues sont des jours
/// civils.
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
          constraints.maxWidth >= AppBreakpoints.formGridTwoColMin
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

/// Les erreurs (bloquantes) et avertissements (non bloquants) de CAL-R7. Un
/// intitulé vide ne s'annonce pas : « Ajouter » reste simplement inactif.
class EventFormMessages extends StatelessWidget {
  final CalendarEventCheck? check;
  final DateTime yearStart;
  final DateTime yearEnd;

  const EventFormMessages({
    super.key,
    required this.check,
    required this.yearStart,
    required this.yearEnd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final check = this.check;
    if (check == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final error in check.errors)
          if (error != CalendarEventError.titleMissing)
            EteeloNotice.error(switch (error) {
              CalendarEventError.endBeforeStart =>
                l10n.schoolCalendarErrorEndBeforeStart,
              CalendarEventError.outOfYear => l10n.schoolCalendarErrorOutOfYear(
                CalendarLabels.day(context, yearStart),
                CalendarLabels.day(context, yearEnd),
              ),
              _ => l10n.schoolCalendarErrorTitleTooLong,
            }),
        for (final warning in check.warnings)
          EteeloNotice.warning(
            warning.isBreakOverlap
                ? l10n.schoolCalendarWarnOverlap(
                    warning.overlapped.title,
                    CalendarLabels.dates(context, warning.overlapped),
                  )
                : l10n.schoolCalendarWarnExam(warning.overlapped.title),
          ),
      ],
    );
  }
}
