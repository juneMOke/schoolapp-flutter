import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';

/// Une année scolaire de l'école, bornes `YYYY-MM-DD` (facultatives : le socle
/// peut les servir vides).
typedef PayrollSchoolYear = ({String? start, String? end});

/// Où en est le Pointage du mois dont la paie lit les heures et les signaux.
enum PayrollAttendanceState {
  /// Clos : son résumé est descendu.
  closed,

  /// Hors de toute année scolaire (août) : compte comme clos et vide (R1).
  outOfYear,

  /// Dans une année, pas encore clos : la validation sera refusée.
  open,

  /// Une année de l'école n'a pas de dates : la tablette ne tranche pas, le
  /// serveur jugera (N3).
  unverifiable,
}

/// La même règle que le serveur (N3) : un mois qui ne recoupe aucune année
/// scolaire de l'école compte comme clos et vide.
abstract final class PayrollAttendanceRule {
  static PayrollAttendanceState stateOf({
    required String month,
    required bool hasSummary,
    required List<PayrollSchoolYear> years,
  }) {
    if (hasSummary) return PayrollAttendanceState.closed;
    if (years.isEmpty ||
        years.any((year) => year.start == null || year.end == null)) {
      return PayrollAttendanceState.unverifiable;
    }
    final inAYear = years.any(
      (year) => PayrollMonth.overlaps(month, year.start!, year.end),
    );
    return inAYear
        ? PayrollAttendanceState.open
        : PayrollAttendanceState.outOfYear;
  }
}
