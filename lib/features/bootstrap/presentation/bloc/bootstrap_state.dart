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

  BootstrapOperation get operation => _operation ?? BootstrapOperation.none;

  const BootstrapState({
    required this.status,
    required this.bootstrap,
    required this.source,
    required this.errorMessage,
    required BootstrapOperation? operation,
  }) : _operation = operation;

  const BootstrapState.initial()
    : status = BootstrapLoadStatus.initial,
      bootstrap = null,
      source = null,
      errorMessage = null,
      _operation = BootstrapOperation.none;

  bool get blocksNavigation =>
      status == BootstrapLoadStatus.initial ||
      (status == BootstrapLoadStatus.loading && operation.blocksNavigation);

  BootstrapState copyWith({
    BootstrapLoadStatus? status,
    Object? bootstrap = _undefined,
    Object? source = _undefined,
    Object? errorMessage = _undefined,
    Object? operation = _undefined,
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
    );
  }

  @override
  List<Object?> get props => [
    status,
    bootstrap,
    source,
    errorMessage,
    operation,
  ];
}
