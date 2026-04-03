part of 'bootstrap_bloc.dart';

const _undefined = Object();

enum BootstrapLoadStatus { initial, loading, success, failure }

enum BootstrapSource { remote, local }

class BootstrapState extends Equatable {
  final BootstrapLoadStatus status;
  final Bootstrap? bootstrap;
  final BootstrapSource? source;
  final String? errorMessage;

  const BootstrapState({
    required this.status,
    required this.bootstrap,
    required this.source,
    required this.errorMessage,
  });

  const BootstrapState.initial()
    : status = BootstrapLoadStatus.initial,
      bootstrap = null,
      source = null,
      errorMessage = null;

  BootstrapState copyWith({
    BootstrapLoadStatus? status,
    Object? bootstrap = _undefined,
    Object? source = _undefined,
    Object? errorMessage = _undefined,
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
    );
  }

  @override
  List<Object?> get props => [status, bootstrap, source, errorMessage];
}
