part of 'hr_staff_list_report_cubit.dart';

const Object _undefined = Object();

enum HrStaffListReportStatus {
  /// Rien en cours — le bouton est armé.
  idle,

  /// Le serveur compose le document. Le bouton est désarmé, et le dit.
  preparing,

  /// Un document long est déjà en production **sur ce serveur** — pas
  /// forcément le nôtre. Le bouton reste désarmé le temps annoncé.
  cooldown,
}

class HrStaffListReportState extends Equatable {
  final HrStaffListReportStatus status;

  /// Le document, **le temps d'être remis** et pas davantage.
  final HrStaffListReport? report;

  /// L'échec, une fois, pour que la vue le dise sans le rejouer.
  final Failure? failure;

  /// Ce que le serveur a demandé d'attendre sur un 429.
  final Duration? retryAfter;

  const HrStaffListReportState({
    this.status = HrStaffListReportStatus.idle,
    this.report,
    this.failure,
    this.retryAfter,
  });

  /// Un second appui ne lance rien : ni pendant le rendu, ni pendant l'attente
  /// qu'un 429 a imposée.
  bool get isBusy =>
      status == HrStaffListReportStatus.preparing ||
      status == HrStaffListReportStatus.cooldown;

  /// Quelque chose est à remettre — un document, ou un mot.
  bool get hasDelivery => report != null || failure != null;

  HrStaffListReportState copyWith({
    HrStaffListReportStatus? status,
    Object? report = _undefined,
    Object? failure = _undefined,
    Object? retryAfter = _undefined,
  }) => HrStaffListReportState(
    status: status ?? this.status,
    report: identical(report, _undefined)
        ? this.report
        : report as HrStaffListReport?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    retryAfter: identical(retryAfter, _undefined)
        ? this.retryAfter
        : retryAfter as Duration?,
  );

  /// Vide ce qui a été remis, **sans toucher au statut** : une attente de 429
  /// court toujours après que son message a été dit.
  HrStaffListReportState clearDelivery() =>
      HrStaffListReportState(status: status, retryAfter: retryAfter);

  @override
  List<Object?> get props => [status, report, failure, retryAfter];
}
