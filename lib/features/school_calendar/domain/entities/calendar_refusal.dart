import 'package:school_app_flutter/core/error/failures.dart';

/// Les refus métier du calendrier, tels que le serveur les nomme dans
/// `detailCode` (422, contrat figé le 2026-11-19). Les codes d'une ligne du
/// lot arrivent, eux, dans `reason` : la même table les lit.
enum CalendarRefusal {
  natureForbidden('CALENDAR_NATURE_FORBIDDEN'),
  datesInvalid('CALENDAR_DATES_INVALID'),
  outOfYear('CALENDAR_OUT_OF_YEAR'),
  archived('CALENDAR_ARCHIVED'),
  elementLocked('CALENDAR_ELEMENT_LOCKED'),
  notFound('CALENDAR_NOT_FOUND'),
  scopeInvalid('CALENDAR_SCOPE_INVALID'),
  eventInvalid('CALENDAR_EVENT_INVALID'),
  frameworkMissing('CALENDAR_FRAMEWORK_MISSING'),
  changed('CALENDAR_CHANGED'),
  yearTaken('CALENDAR_YEAR_TAKEN'),
  yearNotCreatable('CALENDAR_YEAR_NOT_CREATABLE'),
  replacementInvalid('CALENDAR_REPLACEMENT_INVALID'),
  alreadyReplaced('CALENDAR_ALREADY_REPLACED'),
  periodsInvalid('CALENDAR_PERIODS_INVALID');

  const CalendarRefusal(this.detailCode);

  final String detailCode;

  static CalendarRefusal? fromDetailCode(String? code) {
    if (code == null) return null;
    for (final refusal in values) {
      if (refusal.detailCode == code) return refusal;
    }
    return null;
  }
}

class CalendarRefusalFailure extends Failure {
  final CalendarRefusal refusal;

  const CalendarRefusalFailure(this.refusal) : super('Refus du calendrier');

  @override
  List<Object?> get props => [refusal];
}
