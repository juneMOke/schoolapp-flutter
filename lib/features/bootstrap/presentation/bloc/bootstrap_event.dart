part of 'bootstrap_bloc.dart';

sealed class BootstrapEvent extends Equatable {
  const BootstrapEvent();

  @override
  List<Object?> get props => [];
}

class BootstrapResetRequested extends BootstrapEvent {
  const BootstrapResetRequested();
}

class BootstrapRemoteCurrentYearRequested extends BootstrapEvent {
  const BootstrapRemoteCurrentYearRequested();
}

class BootstrapRemotePreviousYearRequested extends BootstrapEvent {
  const BootstrapRemotePreviousYearRequested();
}

class BootstrapLocalRequested extends BootstrapEvent {
  final String key;

  const BootstrapLocalRequested({required this.key});

  @override
  List<Object?> get props => [key];
}

class BootstrapClearLocalRequested extends BootstrapEvent {
  final String key;

  const BootstrapClearLocalRequested({required this.key});

  @override
  List<Object?> get props => [key];
}
