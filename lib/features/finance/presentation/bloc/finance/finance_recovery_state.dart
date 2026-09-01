part of 'finance_recovery_bloc.dart';

const Object _undefined = Object();

enum FinanceRecoveryStatus { initial, loading, success, error }

class FinanceRecoveryState extends Equatable {
  final FinanceRecoveryStatus status;
  final FinanceRecovery? recovery;

  /// **L'échec lui-même, pas une catégorie qu'on en aurait tirée.**
  ///
  /// L'anatomie d'erreur partagée décide de son médaillon, de son titre et de
  /// son geste depuis le [Failure] — et un 500 y porte en plus son code
  /// d'incident. Reprojeter d'abord sur un enum maison perdait ce code et
  /// obligeait à tenir deux taxonomies parallèles de la même chose.
  final Failure? failure;

  const FinanceRecoveryState({
    this.status = FinanceRecoveryStatus.initial,
    this.recovery,
    this.failure,
  });

  FinanceRecoveryState copyWith({
    FinanceRecoveryStatus? status,
    Object? recovery = _undefined,
    Object? failure = _undefined,
  }) => FinanceRecoveryState(
    status: status ?? this.status,
    recovery: identical(recovery, _undefined)
        ? this.recovery
        : recovery as FinanceRecovery?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
  );

  @override
  List<Object?> get props => [status, recovery, failure];
}
