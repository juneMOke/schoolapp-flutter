part of 'relance_list_cubit.dart';

const Object _undefined = Object();

enum RelanceListStatus {
  /// Rien en cours — la ligne est armée.
  idle,

  /// Le corps monte et le serveur compose. La ligne est désarmée, et le dit.
  preparing,

  /// Un document long est déjà en production **sur ce serveur** — pas
  /// forcément le nôtre. La ligne reste désarmée le temps annoncé.
  cooldown,
}

class RelanceListState extends Equatable {
  final RelanceListStatus status;

  /// Le document, **le temps d'être remis** et pas davantage. Voir
  /// [RelanceListCubit.acknowledge].
  final RelanceList? document;

  /// L'échec, une fois, pour que la vue le dise sans le rejouer.
  final Failure? failure;

  /// Ce que le serveur a demandé d'attendre sur un 429.
  final Duration? retryAfter;

  const RelanceListState({
    this.status = RelanceListStatus.idle,
    this.document,
    this.failure,
    this.retryAfter,
  });

  /// Un second appui ne doit rien lancer : ni pendant le rendu, ni pendant
  /// l'attente qu'un 429 a imposée.
  bool get isBusy =>
      status == RelanceListStatus.preparing ||
      status == RelanceListStatus.cooldown;

  RelanceListState clearDelivery() =>
      RelanceListState(status: status, retryAfter: retryAfter);

  RelanceListState copyWith({
    RelanceListStatus? status,
    Object? document = _undefined,
    Object? failure = _undefined,
    Object? retryAfter = _undefined,
  }) => RelanceListState(
    status: status ?? this.status,
    document: identical(document, _undefined)
        ? this.document
        : document as RelanceList?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    retryAfter: identical(retryAfter, _undefined)
        ? this.retryAfter
        : retryAfter as Duration?,
  );

  @override
  List<Object?> get props => [status, document, failure, retryAfter];
}
