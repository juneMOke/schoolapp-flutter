import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';

/// Le cycle d'un geste lancé depuis une modale : au repos, en cours, fait,
/// ou en échec — la saisie est alors conservée pour un nouvel essai.
sealed class SuspensionGestureState extends Equatable {
  const SuspensionGestureState();

  @override
  List<Object?> get props => [];
}

final class SuspensionGestureIdle extends SuspensionGestureState {
  const SuspensionGestureIdle();
}

final class SuspensionGestureBusy extends SuspensionGestureState {
  const SuspensionGestureBusy();
}

final class SuspensionGestureDone extends SuspensionGestureState {
  /// Élèves effectivement touchés.
  final int count;

  const SuspensionGestureDone(this.count);

  @override
  List<Object?> get props => [count];
}

final class SuspensionGestureFailed extends SuspensionGestureState {
  final Failure failure;

  const SuspensionGestureFailed(this.failure);

  @override
  List<Object?> get props => [failure];
}
