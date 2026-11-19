import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';

/// Ce que le compte courant peut faire sur le calendrier (K10, contrat du
/// 2026-11-19) : `calendar.assessment.write` pour les interrogations et les
/// examens, `calendar.holiday.write` pour les congés, `calendar.life.write`
/// pour la vie de l'école, `calendar.publish` pour créer, dupliquer, publier.
/// Le serveur refuse de toute façon une nature hors du droit.
class CalendarRights {
  final Set<CalendarNature> writableNatures;
  final bool canPublish;

  const CalendarRights({
    this.writableNatures = const {},
    this.canPublish = false,
  });

  factory CalendarRights.of(BuildContext context) {
    bool has(Perm p) => PermissionGate.allows(context, [p]);
    return CalendarRights(
      writableNatures: {
        if (has(Perm.calendarAssessmentWrite)) ...[
          CalendarNature.assessment,
          CalendarNature.exam,
        ],
        if (has(Perm.calendarHolidayWrite)) CalendarNature.holidayBreak,
        if (has(Perm.calendarLifeWrite)) CalendarNature.schoolLife,
      },
      canPublish: has(Perm.calendarPublish),
    );
  }

  bool get canWrite => writableNatures.isNotEmpty;

  /// Changer la nature exige le droit de l'ancienne et de la nouvelle : on ne
  /// modifie donc qu'un élément dont on tient la nature.
  bool canEdit(CalendarNature nature) => writableNatures.contains(nature);
}
