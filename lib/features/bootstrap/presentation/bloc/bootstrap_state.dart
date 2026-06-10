part of 'bootstrap_bloc.dart';

const _undefined = Object();

enum BootstrapLoadStatus { initial, loading, success, failure }

enum BootstrapSource { remote, local }

enum BootstrapOperation {
  none,
  remoteCurrentYear,
  remotePreviousYear,
  local,
  clearLocal,
}

extension BootstrapOperationX on BootstrapOperation {
  bool get blocksNavigation =>
      this == BootstrapOperation.remoteCurrentYear ||
      this == BootstrapOperation.remotePreviousYear;
}

class BootstrapState extends Equatable {
  final BootstrapLoadStatus status;
  final Bootstrap? bootstrap;
  final BootstrapSource? source;
  final String? errorMessage;
  final BootstrapOperation? _operation;

  /// `true` quand un bootstrap distant a été rejeté pour cause d'authentification
  /// (401/403) : la session n'est plus valide côté serveur → main.dart déclenche
  /// un logout. Voir [BootstrapBloc] et le couplage main/auth.
  final bool sessionExpired;

  BootstrapOperation get operation => _operation ?? BootstrapOperation.none;

  const BootstrapState({
    required this.status,
    required this.bootstrap,
    required this.source,
    required this.errorMessage,
    required BootstrapOperation? operation,
    this.sessionExpired = false,
  }) : _operation = operation;

  const BootstrapState.initial()
    : status = BootstrapLoadStatus.initial,
      bootstrap = null,
      source = null,
      errorMessage = null,
      sessionExpired = false,
      _operation = BootstrapOperation.none;

  /// `true` dès qu'une donnée bootstrap utilisable est disponible (cache local
  /// ou réponse distante). C'est le pivot de l'approche offline-first : avec des
  /// données, on n'a plus besoin de bloquer l'utilisateur sur le splash.
  bool get hasData => bootstrap != null;

  /// Bloque la navigation (écran d'attente) UNIQUEMENT tant qu'aucune donnée
  /// utilisable n'existe et qu'on n'est pas déjà en échec distant. Dès qu'un
  /// cache est chargé, on entre dans l'app et le réseau rafraîchit en fond.
  bool get blocksNavigation =>
      !hasData &&
      !(status == BootstrapLoadStatus.failure && operation.blocksNavigation);

  /// Seul cas réellement bloquant : AUCUNE donnée utilisable ET un bootstrap
  /// distant a échoué → ErrorView + Réessayer sur le splash.
  bool get hasBlockingFailure =>
      !hasData &&
      status == BootstrapLoadStatus.failure &&
      operation.blocksNavigation;

  /// `true` quand on affiche des données en cache parce que le rafraîchissement
  /// distant a échoué : mode hors-ligne / données potentiellement périmées.
  bool get isStale =>
      source == BootstrapSource.local && status == BootstrapLoadStatus.failure;

  BootstrapState copyWith({
    BootstrapLoadStatus? status,
    Object? bootstrap = _undefined,
    Object? source = _undefined,
    Object? errorMessage = _undefined,
    Object? operation = _undefined,
    bool? sessionExpired,
  }) {
    return BootstrapState(
      status: status ?? this.status,
      bootstrap: identical(bootstrap, _undefined)
          ? this.bootstrap
          : bootstrap as Bootstrap?,
      source: identical(source, _undefined)
          ? this.source
          : source as BootstrapSource?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
      operation: identical(operation, _undefined)
          ? this.operation
          : operation as BootstrapOperation?,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props => [
    status,
    bootstrap,
    source,
    errorMessage,
    operation,
    sessionExpired,
  ];
}
