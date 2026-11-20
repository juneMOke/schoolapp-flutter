import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_refusal.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les textes du calendrier scolaire qui se composent (dates, portées,
/// périodes), écrits une fois.
class CalendarLabels {
  const CalendarLabels._();

  static String nature(AppLocalizations l10n, CalendarNature nature) =>
      l10n.schoolCalendarNature(nature.wire);

  static String natureShort(AppLocalizations l10n, CalendarNature nature) =>
      l10n.schoolCalendarNatureShort(nature.wire);

  static String phase(AppLocalizations l10n, CalendarPhase phase) =>
      l10n.schoolCalendarPhase(phase.wire);

  /// « 9 → 10 juin » ; un seul jour : « mardi 30 juin ».
  static String dates(BuildContext context, CalendarElement element) =>
      range(context, element.startDate, element.endDate);

  static String range(BuildContext context, DateTime start, DateTime end) {
    final dates = MaterialLocalizations.of(context);
    if (start == end) return dates.formatFullDate(start).toLowerCaseFirst();
    return '${dates.formatShortMonthDay(start)} → ${dates.formatShortMonthDay(end)}';
  }

  static String day(BuildContext context, DateTime day) =>
      MaterialLocalizations.of(context).formatMediumDate(day);

  static String scope(
    AppLocalizations l10n,
    CalendarScope scope,
    CalendarScopeOptions options,
  ) => switch (scope) {
    SchoolScope() => l10n.schoolCalendarScopeSchool,
    CycleScope(:final cycleCode) => l10n.schoolCalendarScopeCycle(
      options.cycleName(cycleCode) ?? cycleCode,
    ),
    LevelScope(:final cycleCode, :final levelCode) =>
      l10n.schoolCalendarScopeLevel(
        options.levelName(cycleCode, levelCode) ?? '$cycleCode/$levelCode',
      ),
    RhythmScope(:final rhythm) => l10n.schoolCalendarScopeRhythm(rhythm.wire),
    CatalogLevelScope(:final catalogLevelCodes) =>
      l10n.schoolCalendarScopeCatalog(catalogLevelCodes.join(', ')),
    UnknownScope(:final raw) => l10n.schoolCalendarScopeCycle(raw),
  };

  /// « P4 · 2e semestre » (A2 de la spec).
  static String? period(AppLocalizations l10n, CalendarElement? element) {
    final rank = element?.subPeriodRank;
    if (element == null || rank == null) return null;
    return l10n.schoolCalendarPeriodLabel(
      rank,
      '${element.periodOrder}',
      element.rhythm?.wire ?? PeriodRhythm.semester.wire,
    );
  }

  /// Le texte d'un refus, par son code ; sinon la raison générique.
  static String failure(AppLocalizations l10n, Failure failure) =>
      failure is CalendarRefusalFailure
      ? l10n.schoolCalendarRefusal(failure.refusal.detailCode)
      : l10n.schoolCalendarRefusal(failure.message);

  static String refusalCode(AppLocalizations l10n, String? code) =>
      l10n.schoolCalendarRefusal(code ?? '');
}

extension on String {
  String toLowerCaseFirst() =>
      isEmpty ? this : '${this[0].toLowerCase()}${substring(1)}';
}
