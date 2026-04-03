part of 'bootstrap_bloc.dart';

sealed class BootstrapEvent extends Equatable {
  const BootstrapEvent();

  @override
  List<Object?> get props => [];
}

class BootstrapResetRequested extends BootstrapEvent {
  const BootstrapResetRequested();
}

class BootstrapRemoteRequested extends BootstrapEvent {
  const BootstrapRemoteRequested();
}

class BootstrapLocalRequested extends BootstrapEvent {
  const BootstrapLocalRequested();
}

class BootstrapClearLocalRequested extends BootstrapEvent {
  const BootstrapClearLocalRequested();
}
