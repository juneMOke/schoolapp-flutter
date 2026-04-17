part of 'bootstrap_context_bloc.dart';

sealed class BootstrapContextEvent extends Equatable {
  const BootstrapContextEvent();

  @override
  List<Object?> get props => [];
}

class BootstrapContextRemoteCurrentYearRequested extends BootstrapContextEvent {
  const BootstrapContextRemoteCurrentYearRequested();
}

class BootstrapContextRemotePreviousYearRequested
    extends BootstrapContextEvent {
  const BootstrapContextRemotePreviousYearRequested();
}

class BootstrapContextLocalRequested extends BootstrapContextEvent {
  final String key;

  const BootstrapContextLocalRequested({required this.key});

  @override
  List<Object?> get props => [key];
}

class BootstrapContextResetRequested extends BootstrapContextEvent {
  const BootstrapContextResetRequested();
}
