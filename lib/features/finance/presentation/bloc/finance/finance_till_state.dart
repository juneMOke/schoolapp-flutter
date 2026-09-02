part of 'finance_till_bloc.dart';

const Object _undefined = Object();

enum FinanceTillStatus { initial, loading, success, error }

class FinanceTillState extends Equatable {
  final FinanceTillStatus status;
  final FinanceTill? till;

  /// L'échec lui-même — voir [FinanceRecoveryState.failure].
  final Failure? failure;

  /// La fenêtre affichée. [TillPeriod.day] au premier montage.
  ///
  /// ⚠️ Aucune **ancre** ici, et c'est délibéré : les quatre grains portent
  /// toujours la fenêtre courante. Le jour où l'écran proposera de viser une
  /// journée passée, l'ancre devra être **remise à zéro à chaque changement de
  /// grain** — le serveur refuse en 400 une ancre qui ne correspond pas à la
  /// période, et un état qui garderait l'ancienne produirait un écran d'erreur
  /// sur un simple clic d'onglet.
  final TillPeriod selectedPeriod;

  const FinanceTillState({
    this.status = FinanceTillStatus.initial,
    this.till,
    this.failure,
    this.selectedPeriod = TillPeriod.day,
  });

  FinanceTillState copyWith({
    FinanceTillStatus? status,
    Object? till = _undefined,
    Object? failure = _undefined,
    TillPeriod? selectedPeriod,
  }) => FinanceTillState(
    status: status ?? this.status,
    till: identical(till, _undefined) ? this.till : till as FinanceTill?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    selectedPeriod: selectedPeriod ?? this.selectedPeriod,
  );

  @override
  List<Object?> get props => [status, till, failure, selectedPeriod];
}
