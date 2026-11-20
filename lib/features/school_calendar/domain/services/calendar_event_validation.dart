import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';

/// Ce qui bloque une saisie (CAL-R7).
enum CalendarEventError {
  endBeforeStart,
  outOfYear,
  titleMissing,
  titleTooLong,
}

/// Un avertissement non bloquant : l'élément national chevauché.
class CalendarEventWarning extends Equatable {
  /// `true` : chevauche un congé ou un jour férié national ;
  /// `false` : interrogations ou examen pendant un examen national.
  final bool isBreakOverlap;
  final CalendarElement overlapped;

  const CalendarEventWarning({
    required this.isBreakOverlap,
    required this.overlapped,
  });

  @override
  List<Object?> get props => [isBreakOverlap, overlapped];
}

class CalendarEventCheck extends Equatable {
  final List<CalendarEventError> errors;
  final List<CalendarEventWarning> warnings;

  const CalendarEventCheck({required this.errors, required this.warnings});

  bool get canSave => errors.isEmpty;

  @override
  List<Object?> get props => [errors, warnings];
}

/// Contrôle d'une saisie d'événement de l'école (CAL-R7), avant tout envoi.
///
/// Le serveur refuse les mêmes erreurs (`CALENDAR_DATES_INVALID`,
/// `CALENDAR_OUT_OF_YEAR`) ; les avertissements, eux, restent à l'écran.
class CalendarEventValidation {
  /// La note d'un événement (contrat : 500 caractères au plus).
  static const int noteMaxLength = 500;

  const CalendarEventValidation._();

  static CalendarEventCheck check({
    required String title,
    required CalendarNature nature,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime yearStart,
    required DateTime yearEnd,
    required List<CalendarElement> nationalElements,
  }) {
    final errors = <CalendarEventError>[];
    final trimmed = title.trim();
    if (trimmed.isEmpty) errors.add(CalendarEventError.titleMissing);
    if (trimmed.length > CalendarElement.titleMaxLength) {
      errors.add(CalendarEventError.titleTooLong);
    }
    final start = CalendarDays.of(startDate);
    final end = CalendarDays.of(endDate);
    if (end.isBefore(start)) errors.add(CalendarEventError.endBeforeStart);
    if (start.isBefore(CalendarDays.of(yearStart)) ||
        end.isAfter(CalendarDays.of(yearEnd))) {
      errors.add(CalendarEventError.outOfYear);
    }

    final warnings = <CalendarEventWarning>[];
    // Une période contient forcément des congés : rien à avertir.
    if (!end.isBefore(start) && nature != CalendarNature.period) {
      final isAssessment =
          nature == CalendarNature.assessment || nature == CalendarNature.exam;
      for (final national in nationalElements) {
        // Un remplacement tient la place de l'élément national (ses dates).
        if (!(national.isNational || national.isReplacement) ||
            !national.overlaps(start, end)) {
          continue;
        }
        final isBreak =
            national.nature == CalendarNature.holidayBreak ||
            national.nature == CalendarNature.publicHoliday;
        if (isBreak) {
          warnings.add(
            CalendarEventWarning(isBreakOverlap: true, overlapped: national),
          );
        } else if (isAssessment && national.nature == CalendarNature.exam) {
          warnings.add(
            CalendarEventWarning(isBreakOverlap: false, overlapped: national),
          );
        }
      }
    }
    return CalendarEventCheck(errors: errors, warnings: warnings);
  }
}
