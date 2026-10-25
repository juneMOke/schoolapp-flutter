import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';

/// Le pas du graphique : un jour par barre, ou un mois au-delà de 31 jours de
/// classe.
enum HrAttendanceGranularity {
  day('DAY'),
  month('MONTH');

  const HrAttendanceGranularity(this.wire);

  final String wire;

  /// Une valeur inconnue se lit jour par jour : le graphique reste lisible.
  static HrAttendanceGranularity fromWire(String? value) =>
      value == month.wire ? month : day;
}

/// Une barre du graphique de présence : un jour (`AAAA-MM-JJ`) ou un mois
/// (`AAAA-MM`).
///
/// Sans pointage, [scored] vaut 0 et les deux taux sont `null` : la barre se
/// dessine en pointillés, sans chiffre. Sinon `absenceRatePct` vaut
/// `100 − presenceRatePct`.
class HrAttendanceBar extends Equatable {
  final String key;
  final int scored;
  final int presences;
  final int absences;
  final int? presenceRatePct;
  final int? absenceRatePct;

  const HrAttendanceBar({
    required this.key,
    required this.scored,
    required this.presences,
    required this.absences,
    required this.presenceRatePct,
    required this.absenceRatePct,
  });

  bool get isEmpty => scored == 0;

  @override
  List<Object?> get props => [
    key,
    scored,
    presences,
    absences,
    presenceRatePct,
    absenceRatePct,
  ];
}

/// Un agent et ses compteurs sur la période.
class HrAttendanceStaffRow extends Equatable {
  final HrAttendanceAgent agent;
  final HrAttendanceKpis kpis;

  const HrAttendanceStaffRow({required this.agent, required this.kpis});

  @override
  List<Object?> get props => [agent, kpis];
}

/// Le tableau de bord d'une période (`GET /hr/attendance-stats`).
///
/// [staff] arrive **déjà trié** : du moins au plus assidu, sans pointage en
/// dernier, égalité par nom. La tablette filtre cette liste, elle ne la
/// retrie jamais — le PDF reprend le même ordre.
class HrAttendanceDashboard extends Equatable {
  /// Bornes effectives (`AAAA-MM-JJ`) : le serveur ramène [to] à aujourd'hui.
  final String from;
  final String to;
  final int classDays;
  final int staffCount;
  final HrAttendanceGranularity granularity;
  final HrAttendanceKpis kpis;
  final List<HrAttendanceBar> series;
  final List<HrAttendanceStaffRow> staff;

  const HrAttendanceDashboard({
    required this.from,
    required this.to,
    required this.classDays,
    required this.staffCount,
    required this.granularity,
    required this.kpis,
    required this.series,
    required this.staff,
  });

  @override
  List<Object?> get props => [
    from,
    to,
    classDays,
    staffCount,
    granularity,
    kpis,
    series,
    staff,
  ];
}
