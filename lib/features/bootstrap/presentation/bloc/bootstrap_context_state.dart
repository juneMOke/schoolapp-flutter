part of 'bootstrap_context_bloc.dart';

enum BootstrapContextLoadStatus { initial, loading, success, failure }

class BootstrapContextState extends Equatable {
  final BootstrapContextLoadStatus status;
  final Bootstrap? bootstrap;
  final String? errorMessage;

  const BootstrapContextState({
    required this.status,
    required this.bootstrap,
    required this.errorMessage,
  });

  const BootstrapContextState.initial()
    : status = BootstrapContextLoadStatus.initial,
      bootstrap = null,
      errorMessage = null;

  BootstrapContextState copyWith({
    BootstrapContextLoadStatus? status,
    Object? bootstrap = const Object(),
    Object? errorMessage = const Object(),
  }) {
    return BootstrapContextState(
      status: status ?? this.status,
      bootstrap: identical(bootstrap, const Object())
          ? this.bootstrap
          : bootstrap as Bootstrap?,
      errorMessage: identical(errorMessage, const Object())
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, bootstrap, errorMessage];
}
