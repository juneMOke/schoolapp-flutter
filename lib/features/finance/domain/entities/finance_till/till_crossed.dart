import 'package:equatable/equatable.dart';

/// Un montant dans une devise nommée — la brique des agrégats qui refusent de
/// s'additionner.
///
/// Existe pour que « 135 $ et 40 000 FC » reste **deux montants**. Un seul
/// champ `int` aurait obligé l'appelant à retenir la devise ailleurs, et c'est
/// exactement là que naît une somme inter-devises.
class TillCurrencyAmount extends Equatable {
  final String currency;

  /// En centimes, dans [currency]. Jamais converti.
  final int amount;

  const TillCurrencyAmount({required this.currency, required this.amount});

  @override
  List<Object?> get props => [currency, amount];
}

/// Les **paiements croisés** de la fenêtre : ceux qui ont réglé un frais fixé
/// dans une autre devise que celle réellement tendue.
///
/// C'est ce qui explique un écart au contrôle de caisse, et la raison d'être de
/// l'encart de lecture. Un frais en dollars réglé en francs alimente la caisse
/// **francs** tout en soldant une créance **dollars** : les deux moitiés du
/// versement ne se comptent pas dans la même unité.
class TillCrossed extends Equatable {
  /// Le nombre de **lignes d'encaissement** croisées, pas de reçus : un reçu qui
  /// a pris des francs et des dollars porte deux lignes, et c'est la ligne qui
  /// est croisée ou non.
  final int count;

  /// Ce que ces croisements pèsent, **une entrée par devise reçue**. Jamais un
  /// total : c'est précisément la somme que la doctrine interdit.
  final List<TillCurrencyAmount> amounts;

  /// Les taux appliqués sur la fenêtre, distincts et ordonnés, en **micro-unités**
  /// — `taux × 1 000 000`, l'échelle de `ExchangeRate.scale`, parce qu'un
  /// flottant qui traverse la couche métier finit par arrondir de l'argent.
  ///
  /// **Une liste et non une valeur**, et c'est le point : un taux changé en
  /// cours de période est justement ce qui explique un écart de caisse. L'encart
  /// dit « au taux de 2 850 » quand il n'y en a qu'un, et doit dire autre chose
  /// quand il y en a plusieurs — il ne peut pas en choisir un.
  ///
  /// Vide quand aucun croisement ne porte de taux.
  final List<int> rateMicros;

  const TillCrossed({
    required this.count,
    required this.amounts,
    required this.rateMicros,
  });

  /// Aucun frais n'a été réglé dans une autre devise que la sienne.
  ///
  /// L'encart reste rendu — avec sa formulation de repli, « aucun paiement
  /// croisé » — parce qu'une carte qui disparaît laisse croire qu'on a oublié de
  /// regarder.
  bool get isEmpty => count == 0;

  /// Plusieurs taux ont eu cours sur la fenêtre : l'encart ne peut pas en citer
  /// un seul sans en taire d'autres.
  bool get hasMultipleRates => rateMicros.length > 1;

  @override
  List<Object?> get props => [count, amounts, rateMicros];
}
