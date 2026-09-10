part of 'finance_till_receipts_bloc.dart';

sealed class FinanceTillReceiptsEvent extends Equatable {
  const FinanceTillReceiptsEvent();

  @override
  List<Object?> get props => [];
}

/// Charger la table pour une fenêtre.
///
/// Émis à la première ouverture **et à chaque changement de fenêtre**, qui
/// remet la pagination à zéro.
///
/// ⚠️ **Une bascule de caisse ne l'émet plus.** La table porte désormais tous
/// les paiements de la période, quelle que soit la caisse examinée au-dessus :
/// la rejouer sur un changement de devise redemanderait exactement la même page
/// et ferait clignoter une table déjà juste.
class FinanceTillReceiptsRequested extends FinanceTillReceiptsEvent {
  final TillWindow window;

  const FinanceTillReceiptsRequested({required this.window});

  @override
  List<Object?> get props => [window];
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
