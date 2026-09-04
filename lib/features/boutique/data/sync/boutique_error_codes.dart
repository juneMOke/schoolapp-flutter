/// Les causes de refus que le serveur nomme dans `detailCode` d'un 422.
///
/// Miroir de `BoutiqueErrorCodes` côté back. Se brancher sur **ces valeurs**,
/// jamais sur le message : celui-ci est rédigé en français pour un humain et se
/// reformule sans préavis.
///
/// ## Ce que chacune veut dire au guichet
///
/// Les trois causes réellement atteignables sont des **bugs client** : aucune ne
/// se résout en attendant, et toutes trois arrivent sur une vente déjà
/// encaissée. C'est pourquoi elles sont surfacées telles quelles plutôt que
/// rejouées jusqu'au poison.
abstract final class BoutiqueErrorCodes {
  /// Le total d'une ligne n'est pas le produit, ou le total de la vente n'est
  /// pas la somme. Le panier a calculé faux — jamais la faute du guichet.
  static const String inconsistentTotal = 'INCONSISTENT_TOTAL';

  /// L'article poussé n'existe pas au catalogue de cette école.
  static const String unknownArticle = 'UNKNOWN_ARTICLE';

  /// L'année poussée n'est pas une année de cette école. Elle aurait créé une
  /// séquence éditique fantôme et rendu la vente invisible au pull.
  static const String unknownAcademicYear = 'UNKNOWN_ACADEMIC_YEAR';

  /// ⚠️ **Déclarée par le serveur mais jamais levée** sur la route de push :
  /// l'ingestion appelle une résolution qui ne lève pas, et consigne une
  /// anomalie plutôt que de refuser une vente encaissée.
  ///
  /// Gardée ici par prudence — l'`openApi.yaml` l'annonce encore — mais **ne
  /// bâtissez aucun parcours de récupération dessus** : il ne se déclenchera
  /// pas.
  static const String priceUnresolvable = 'PRICE_UNRESOLVABLE';

  /// Le perçu déclaré, converti au taux fourni, n'éteint pas ce que la vente
  /// vaut — vérifié **par devise pivot**, à une unité d'affichage près.
  ///
  /// Même famille que [inconsistentTotal] : le panier a calculé faux. Le
  /// `TenderComposition.check` posé avant l'écriture existe pour que ce refus
  /// n'arrive jamais sur une vente déjà encaissée.
  static const String tenderSumMismatch = 'TENDER_SUM_MISMATCH';

  /// Le pivot déclaré n'est soldé par aucune ligne du panier.
  ///
  /// La déclaration dit « ces francs éteignent des dollars » alors qu'aucune
  /// ligne vendue n'est en dollars. Le panier désigne mal, l'attente n'y peut
  /// rien.
  static const String unknownTenderPivot = 'UNKNOWN_TENDER_PIVOT';

  /// Vrai si la cause est un défaut de composition du panier, donc à corriger
  /// dans l'application et non au guichet.
  static bool isClientDefect(String? detailCode) =>
      detailCode == inconsistentTotal ||
      detailCode == unknownArticle ||
      detailCode == unknownAcademicYear ||
      detailCode == tenderSumMismatch ||
      detailCode == unknownTenderPivot;
}
