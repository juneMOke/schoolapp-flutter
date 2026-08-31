import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';

/// Résout le prix d'une ligne de vente — **le seul chemin** par lequel un
/// montant entre dans un panier (invariant I-2).
///
/// L'écran n'a aucun champ de montant, ni sur la ligne ni dans la confirmation.
/// Une ligne walk-in demande un **niveau** (liste fermée), jamais un prix. Le
/// total est calculé, jamais saisi.
///
/// ## Ce que `null` veut dire
///
/// `null` = **ligne incomplète**, et jamais `0`. La différence porte de
/// l'argent : une ligne à zéro s'additionne en silence et se vend gratuitement,
/// une ligne nulle se signale elle-même à l'écran (« Prix à résoudre ») et
/// bloque l'encaissement. C'est aussi pourquoi rien ici ne replie sur une valeur
/// par défaut.
abstract final class BoutiquePriceResolver {
  /// Le prix unitaire, en cents, ou `null` si la ligne n'est pas résolue.
  ///
  /// [levelId] est le **niveau effectif** de la ligne : celui de l'élève quand
  /// un bénéficiaire est désigné, celui choisi au guichet sinon. La distinction
  /// n'appartient pas à cette fonction — elle est faite par
  /// [effectiveLevelIdOf], une seule fois, pour qu'aucun autre chemin ne
  /// l'invente.
  static int? resolve(BoutiqueArticle article, {String? levelId}) {
    switch (article.pricingMode) {
      case PricingMode.prixUnique:
        // Ni le bénéficiaire ni le niveau n'entrent dans le calcul : c'est le
        // cas de l'écusson vendu au premier venu, et il ne doit rien demander
        // à personne.
        return article.unitPriceInCents;
      case PricingMode.prixParNiveau:
        if (levelId == null) return null;
        return article.levelPrices[levelId];
      case null:
        // Mode illisible : invendable. Rendre le prix unique par défaut le
        // ferait vendre sans qu'on demande le niveau, donc au mauvais tarif.
        return null;
    }
  }

  /// Le niveau qui résout le prix : **l'élève emporte son niveau**.
  ///
  /// Une seule fonction, et aucun autre chemin. Les deux entrées sont
  /// mutuellement exclusives à l'écran (désigner un bénéficiaire fait
  /// disparaître le sélecteur de niveau), mais les recevoir toutes deux ne doit
  /// pas produire un arbitrage différent selon l'appelant : c'est le
  /// bénéficiaire qui gagne, ici comme côté serveur, qui **ignore** le niveau
  /// déclaré dès qu'un bénéficiaire est nommé.
  static String? effectiveLevelIdOf({
    String? beneficiaryLevelId,
    String? declaredLevelId,
  }) => beneficiaryLevelId ?? declaredLevelId;

  /// Vrai si la ligne doit encore réclamer un niveau à l'écran.
  ///
  /// Distinct de « le prix est nul » : un article à grille dont le niveau est
  /// choisi mais absent de la grille n'a pas de prix **et** n'a plus rien à
  /// demander — c'est un trou de catalogue, pas une saisie inachevée.
  static bool needsLevel(BoutiqueArticle article, {String? levelId}) =>
      article.requiresLevel && levelId == null;
}
