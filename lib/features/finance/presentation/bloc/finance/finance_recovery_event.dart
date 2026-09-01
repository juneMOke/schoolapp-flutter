part of 'finance_recovery_bloc.dart';

sealed class FinanceRecoveryEvent extends Equatable {
  const FinanceRecoveryEvent();

  @override
  List<Object?> get props => [];
}

/// Charger — ou recharger — le recouvrement de l'année courante.
///
/// Sans paramètre : il n'y a pas de fenêtre à viser. Le rafraîchissement après
/// une erreur passe par ce même évènement.
class FinanceRecoveryRequested extends FinanceRecoveryEvent {
  const FinanceRecoveryRequested();
}
