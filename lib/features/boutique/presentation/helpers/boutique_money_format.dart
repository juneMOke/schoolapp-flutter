/// Mise en forme des montants de la caisse.
///
/// Deux formes, et la distinction vient de la spec (§00) : **entier abrégé sur
/// les cartes** (« 10 $ », parce qu'un catalogue se parcourt d'un coup d'œil) et
/// **deux décimales sur les totaux et les documents** (« 35.00 $ », parce qu'un
/// ticket se recompte).
///
/// Les montants sont **toujours en cents** : la conversion se fait ici et
/// nulle part ailleurs. Un `double` qui traverserait la couche métier finirait
/// par arrondir de l'argent.
abstract final class BoutiqueMoneyFormat {
  /// Symbole affiché pour une devise.
  ///
  /// Le dollar est abrégé parce que le pilote vend en USD et que le guichet lit
  /// « $ » plus vite que « USD ». Toute autre devise garde son code : inventer
  /// un symbole pour le franc congolais ferait lire « 10 F » là où l'école
  /// écrit « 10 FC ».
  static String symbolOf(String currency) =>
      currency.toUpperCase() == 'USD' ? r'$' : currency.toUpperCase();

  /// « 10 $ » — pour les cartes du catalogue.
  ///
  /// Les centimes non nuls ne sont **pas** escamotés : un article à 10,50 $
  /// affiché « 10 $ » ferait recompter le ticket au client, et c'est le seul
  /// endroit où l'abrégé pourrait mentir.
  static String compact(int cents, String currency) {
    final symbol = symbolOf(currency);
    if (cents % 100 == 0) return '${cents ~/ 100} $symbol';
    return '${(cents / 100).toStringAsFixed(2)} $symbol';
  }

  /// « 35.00 $ » — pour les totaux, la confirmation et les documents.
  static String exact(int cents, String currency) =>
      '${(cents / 100).toStringAsFixed(2)} ${symbolOf(currency)}';
}
