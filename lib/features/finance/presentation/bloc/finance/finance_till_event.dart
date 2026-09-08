part of 'finance_till_bloc.dart';

sealed class FinanceTillEvent extends Equatable {
  const FinanceTillEvent();

  @override
  List<Object?> get props => [];
}

/// Totaliser la caisse sur une fenêtre.
///
/// Le défaut est [TillPeriod.day] : la question qu'on pose le soir, à la
/// fermeture. C'est aussi ce que le serveur prend par défaut, mais le grain est
/// envoyé explicitement — un défaut qui vit des deux côtés finit par diverger
/// d'un seul.
class FinanceTillRequested extends FinanceTillEvent {
  final TillWindow window;

  const FinanceTillRequested({this.window = const TillWindow.day()});

  @override
  List<Object?> get props => [window];
}

/// Recharger la fenêtre en cours — le geste du bouton « Réessayer ».
class FinanceTillRefreshRequested extends FinanceTillEvent {
  const FinanceTillRefreshRequested();
}

/// Détailler une autre caisse.
///
/// **Ne rejoue aucun chargement** : les deux caisses arrivent dans la même
/// réponse, et tout ce qui change est la moitié qu'on regarde. Rappeler le
/// serveur pour un choix déjà en mémoire ferait clignoter un écran entier sur
/// un geste qui n'a rien demandé de neuf.
class FinanceTillCurrencySelected extends FinanceTillEvent {
  final String currency;

  const FinanceTillCurrencySelected(this.currency);

  @override
  List<Object?> get props => [currency];
}
