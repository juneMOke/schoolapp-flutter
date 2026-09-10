part of 'finance_till_report_cubit.dart';

const Object _undefined = Object();

enum FinanceTillReportStatus {
  /// Rien en cours — le bouton est armé.
  idle,

  /// Le serveur compose le document. Le bouton est désarmé, et le dit.
  preparing,

  /// Le serveur produit déjà un rapport pour quelqu'un d'autre. Le bouton reste
  /// désarmé le temps qu'il a annoncé.
  cooldown,
}

class FinanceTillReportState extends Equatable {
  final FinanceTillReportStatus status;

  /// Le document, **le temps d'être remis** et pas davantage. Voir
  /// [FinanceTillReportCubit.acknowledge].
  final TillReport? report;

  /// L'échec, une fois, pour que la vue le dise sans le rejouer.
  final Failure? failure;

  /// Ce que le serveur a demandé d'attendre sur un 429.
  final Duration? retryAfter;

  const FinanceTillReportState({
    this.status = FinanceTillReportStatus.idle,
    this.report,
    this.failure,
    this.retryAfter,
  });

  /// Un second appui ne doit rien lancer : ni pendant le rendu, ni pendant
  /// l'attente qu'un 429 a imposée.
  bool get isBusy =>
      status == FinanceTillReportStatus.preparing ||
      status == FinanceTillReportStatus.cooldown;

  /// Quelque chose est à remettre à l'utilisateur — un document, ou un mot.
  bool get hasDelivery => report != null || failure != null;

  FinanceTillReportState copyWith({
    FinanceTillReportStatus? status,
    Object? report = _undefined,
    Object? failure = _undefined,
    Object? retryAfter = _undefined,
  }) => FinanceTillReportState(
    status: status ?? this.status,
    report: identical(report, _undefined) ? this.report : report as TillReport?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    retryAfter: identical(retryAfter, _undefined)
        ? this.retryAfter
        : retryAfter as Duration?,
  );

  /// Vide ce qui a été remis, **sans toucher au statut** : une attente de 429
  /// court toujours après que son message a été dit.
  FinanceTillReportState clearDelivery() =>
      FinanceTillReportState(status: status, retryAfter: retryAfter);

  @override
  List<Object?> get props => [status, report, failure, retryAfter];
}
