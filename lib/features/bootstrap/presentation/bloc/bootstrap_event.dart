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

/// Réessai du bootstrap distant déclenché depuis le splash (après un échec).
///
/// Le widget ne déclenche jamais les fetch distants directement (règle du
/// module) : il émet ce signal, et le bloc relance lui-même les opérations
/// distantes (année courante + précédente).
class BootstrapRetryRequested extends BootstrapEvent {
  const BootstrapRetryRequested();
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
