part of 'hr_attendance_report_cubit.dart';

const Object _undefined = Object();

enum HrAttendanceReportStatus {
  /// Rien en cours — le bouton est armé.
  idle,

  /// Le serveur compose le document. Le bouton est désarmé, et le dit.
  preparing,

  /// Un document long est déjà en production sur ce serveur. Le bouton reste
  /// désarmé le temps annoncé.
  cooldown,
}

class HrAttendanceReportState extends Equatable {
  final HrAttendanceReportStatus status;

  /// Le document, **le temps d'être remis** et pas davantage.
  final HrAttendanceReport? report;

  /// L'échec, une fois, pour que la vue le dise sans le rejouer.
  final Failure? failure;

  /// Ce que le serveur a demandé d'attendre sur un 429.
  final Duration? retryAfter;

  const HrAttendanceReportState({
    this.status = HrAttendanceReportStatus.idle,
    this.report,
    this.failure,
    this.retryAfter,
  });

  bool get isBusy =>
      status == HrAttendanceReportStatus.preparing ||
      status == HrAttendanceReportStatus.cooldown;

  bool get hasDelivery => report != null || failure != null;

  HrAttendanceReportState copyWith({
    HrAttendanceReportStatus? status,
    Object? report = _undefined,
    Object? failure = _undefined,
    Object? retryAfter = _undefined,
  }) => HrAttendanceReportState(
    status: status ?? this.status,
    report: identical(report, _undefined)
        ? this.report
        : report as HrAttendanceReport?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    retryAfter: identical(retryAfter, _undefined)
        ? this.retryAfter
        : retryAfter as Duration?,
  );

  /// Vide ce qui a été remis, sans toucher au statut : une attente de 429
  /// court toujours après que son message a été dit.
  HrAttendanceReportState clearDelivery() =>
      HrAttendanceReportState(status: status, retryAfter: retryAfter);

  @override
  List<Object?> get props => [status, report, failure, retryAfter];
}
