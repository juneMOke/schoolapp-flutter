/// La forme sous laquelle une borne se compare à `boutique_sales.sold_at`.
///
/// ⚠️ **Tronquée à la seconde, sans suffixe.** `sold_at` mélange deux formats :
/// l'écriture locale produit `...T11:42:00.000Z`, le delta serveur descend
/// `...T11:42:00Z`. Or `'.'` (0x2E) est INFÉRIEUR à `'Z'` (0x5A) : une borne
/// écrite `...T00:00:00Z` exclurait une vente locale de minuit pile, et une
/// borne `...T00:00:00.000Z` en exclurait une du serveur. Un préfixe de 19
/// caractères est plus petit que les deux, et reste exploitable par l'index —
/// c'est une comparaison de préfixe, pas une fonction sur la colonne.
abstract final class SoldAtBound {
  static String of(DateTime instant) =>
      instant.toUtc().toIso8601String().substring(0, 19);
}
