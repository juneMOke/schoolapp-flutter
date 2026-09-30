/// Les valeurs fermées du Pointage (RH, sous-module B), avec leur forme sur le
/// fil. Même lecture tolérante que le fichier du personnel : une valeur
/// inconnue se lit `null`, jamais une exception.
library;

import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Statut d'un agent pour un jour.
///
/// [none] n'est pas une absence de ligne : c'est un pointage **effacé**, qui
/// part au serveur comme une modification (jamais une suppression).
enum StaffAttendanceStatus implements StaffWired {
  none('NONE'),
  present('PRESENT'),
  late('RETARD'),
  absent('ABSENT');

  const StaffAttendanceStatus(this.wire);
  @override
  final String wire;

  static StaffAttendanceStatus? fromWire(String? value) =>
      staffByWire(values, value);

  /// Le statut porte-t-il une heure d'arrivée ?
  bool get hasArrival => this == present || this == late;

  /// Le statut admet-il une justification ?
  bool get isIncident => this == late || this == absent;

  /// Pointé : tout sauf « à pointer ».
  bool get isMarked => this != none;
}

/// Motif d'une justification. Codes français, libellés tenus par la tablette.
enum StaffAbsenceReason implements StaffWired {
  illness('MALADIE'),
  transport('TRANSPORT'),
  bereavement('DEUIL'),
  family('FAMILLE'),
  mission('MISSION'),
  training('FORMATION'),
  other('AUTRE');

  const StaffAbsenceReason(this.wire);
  @override
  final String wire;

  static StaffAbsenceReason? fromWire(String? value) =>
      staffByWire(values, value);
}

/// Ce qu'un verrou fige : un jour (le rapport journalier) ou un mois (la
/// clôture).
enum StaffAttendanceLockKind implements StaffWired {
  day('DAY'),
  month('MONTH');

  const StaffAttendanceLockKind(this.wire);
  @override
  final String wire;

  static StaffAttendanceLockKind? fromWire(String? value) =>
      staffByWire(values, value);
}

/// Un geste sur un verrou. Chacun part seul, sous son propre identifiant :
/// deux gestes ne fusionnent jamais.
enum StaffAttendanceGesture implements StaffWired {
  validateDay('VALIDATE_DAY', StaffAttendanceLockKind.day, locks: true),
  reopenDay('REOPEN_DAY', StaffAttendanceLockKind.day, locks: false),
  closeMonth('CLOSE_MONTH', StaffAttendanceLockKind.month, locks: true);

  const StaffAttendanceGesture(this.wire, this.kind, {required this.locks});
  @override
  final String wire;

  /// La période que le geste touche.
  final StaffAttendanceLockKind kind;

  /// L'état qu'il laisse : verrouillé, ou rouvert.
  final bool locks;

  static StaffAttendanceGesture? fromWire(String? value) =>
      staffByWire(values, value);
}
