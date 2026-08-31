import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';

/// Mise en forme des montants de la caisse.
///
/// Deux formes, et la distinction vient de la spec (§00) : **entier abrégé sur
/// les cartes** (« 10 $ », parce qu'un catalogue se parcourt d'un coup d'œil) et
/// **la forme exacte sur les totaux et les documents** (« 35,00 $ », parce qu'un
/// ticket se recompte).
///
/// Les montants sont **toujours en cents** : la conversion se fait dans
/// [MoneyFormat] et nulle part ailleurs. Un `double` qui traverserait la couche
/// métier finirait par arrondir de l'argent.
///
/// ## Ce qui a changé avec le multi-devise
///
/// Cette classe portait sa propre règle — symbole `$` pour le dollar, code brut
/// pour le reste, deux décimales toujours, point décimal, aucun groupement de
/// milliers. Elle est devenue une **façade** sur [MoneyFormat], qui sait en plus
/// que `CDF` s'écrit « FC » et n'a pas de décimales. Trois rendus changent, et
/// c'était le but : `90000.00 CDF` s'écrit désormais `90 000 FC`.
abstract final class BoutiqueMoneyFormat {
  /// Symbole affiché pour une devise.
  ///
  /// Le dollar est abrégé parce que le guichet lit « $ » plus vite que « USD ».
  /// Le franc s'écrit « FC », comme l'école l'écrit. Toute autre devise garde
  /// son code : inventer un symbole ferait lire autre chose que le réel.
  static String symbolOf(String currency) => MoneyFormat.symbolOf(currency);

  /// « 10 $ » — pour les cartes du catalogue.
  ///
  /// Les centimes non nuls ne sont **pas** escamotés : un article à 10,50 $
  /// affiché « 10 $ » ferait recompter le ticket au client, et c'est le seul
  /// endroit où l'abrégé pourrait mentir.
  static String compact(
    int cents,
    String currency, {
    String space = MoneyFormat.nbsp,
  }) => MoneyFormat.compact(Money.parse(cents, currency), space: space);

  /// « 35,00 $ » — pour les totaux, la confirmation et les documents.
  ///
  /// [space] sépare les milliers **et** le montant de son abréviation. Le
  /// défaut est l'insécable, qui empêche un montant de se couper en fin de
  /// ligne à l'écran. **Le ticket thermique doit passer
  /// [MoneyFormat.thermalSpace]** : une imprimante ne rend l'insécable que si sa
  /// page de code est bien celle qu'on croit, et le parc a déjà tranché de
  /// l'éviter (cf. `TicketTextLayout.formatAmount`).
  static String exact(
    int cents,
    String currency, {
    String space = MoneyFormat.nbsp,
  }) => MoneyFormat.format(Money.parse(cents, currency), space: space);
}
