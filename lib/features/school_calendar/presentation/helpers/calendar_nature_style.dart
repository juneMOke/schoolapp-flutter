import 'package:school_app_flutter/core/theme/school_calendar_tones.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';

/// La teinte partagée (`SchoolCalendarTones`, dans `core`) de chaque nature.
extension CalendarNatureStyle on CalendarNature {
  CalendarNatureTone get tone => switch (this) {
    CalendarNature.period => SchoolCalendarTones.period,
    CalendarNature.assessment => SchoolCalendarTones.assessment,
    CalendarNature.exam => SchoolCalendarTones.exam,
    CalendarNature.holidayBreak => SchoolCalendarTones.holidayBreak,
    CalendarNature.publicHoliday => SchoolCalendarTones.publicHoliday,
    CalendarNature.schoolLife => SchoolCalendarTones.schoolLife,
  };
}
