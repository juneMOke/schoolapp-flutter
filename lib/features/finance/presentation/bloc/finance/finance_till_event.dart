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
  final TillPeriod period;

  const FinanceTillRequested({this.period = TillPeriod.day});

  @override
  List<Object?> get props => [period];
}

/// Recharger la fenêtre en cours — le geste du bouton « Réessayer ».
class FinanceTillRefreshRequested extends FinanceTillEvent {
  const FinanceTillRefreshRequested();
}
