import 'package:equatable/equatable.dart';

/// Les quatre chiffres du recouvrement, dans une devise.
///
/// Ordre de lecture : l'**encaissé** est un flux, l'**attendu** et le **reste
/// dû** sont un état.
class FinanceKpis extends Equatable {
  /// Encaissé sur l'année scolaire, en centimes. Cadré par l'année, **pas par
  /// une date** : un versement rattaché à l'année reste de l'argent recouvré
  /// même daté après la clôture calendaire de sa fenêtre.
  final int collected;

  /// Facturé sur l'année scolaire, en centimes.
  final int expected;

  /// Ce qui reste dû sur ces créances, en centimes — la somme de
  /// `max(attendu − payé, 0)` prise **créance par créance**.
  ///
  /// Ce n'est **pas** `expected - collected` : les deux se lisent sur des
  /// populations différentes, et la soustraction passait négative dès qu'un
  /// élève payait en trop. Toujours dans `[0, expected]` — le trop-perçu d'un
  /// élève n'efface jamais l'arriéré d'un autre.
  final int outstanding;

  /// `(expected − outstanding) / expected × 100` : la part du **facturé** qui
  /// est soldée, si bien que le taux et le montant d'à côté parlent de la même
  /// chose.
  ///
  /// Il valait `collected / expected`, qui franchissait 100 % dès qu'un
  /// versement soldait une créance d'un autre exercice.
  final int collectionRate;

  const FinanceKpis({
    required this.collected,
    required this.expected,
    required this.outstanding,
    required this.collectionRate,
  });

  /// Rien n'était attendu : le serveur rend alors un taux de **100**, qui se
  /// lit « rien ne manque » et non « tout a été recouvré ».
  ///
  /// La distinction est nommée ici, une fois, plutôt que redérivée par chaque
  /// widget qui affiche un taux : sur une devise dormante — et elles sont
  /// désormais renvoyées à zéro plutôt qu'absentes — un 100 % triomphant serait
  /// un contresens. L'écran doit poser un tiret.
  bool get hasNoExpectation => expected == 0;

  @override
  List<Object?> get props => [collected, expected, outstanding, collectionRate];
}
