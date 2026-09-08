part of 'finance_till_receipts_bloc.dart';

sealed class FinanceTillReceiptsEvent extends Equatable {
  const FinanceTillReceiptsEvent();

  @override
  List<Object?> get props => [];
}

/// Charger la table pour une caisse et une fenêtre.
///
/// Émis à la première ouverture, **et à chaque bascule de caisse ou de
/// fenêtre** : les deux changent ce que la table décrit, et remettent donc la
/// pagination à zéro.
class FinanceTillReceiptsRequested extends FinanceTillReceiptsEvent {
  final String currency;
  final TillPeriod period;

  const FinanceTillReceiptsRequested({
    required this.currency,
    required this.period,
  });

  @override
  List<Object?> get props => [currency, period];
}

/// Tourner une page — **sans changer ni la caisse ni la fenêtre**.
///
/// La page est servie par le serveur : il n'existe pas de version « côté
/// client » de ce geste, et filtrer une page reçue donnerait un compteur faux.
class FinanceTillReceiptsPageChanged extends FinanceTillReceiptsEvent {
  final int page;

  const FinanceTillReceiptsPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}
