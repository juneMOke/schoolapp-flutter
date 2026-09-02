/// Répartir un montant sur les tranches d'une nature — **en cascade** (GE-0).
///
/// Le caissier tape 120 000 sur un minerval à trois tranches restantes
/// (50 000 · 50 000 · 50 000) ; l'écran solde la première, puis la deuxième, et
/// pose le reste sur la troisième.
///
/// ## Pourquoi la cascade, et surtout pas un prorata
///
/// La cascade remplit chaque tranche **à son restant exact**, sans jamais
/// diviser. Elle est donc juste au centime *par construction* : il n'y a aucun
/// arrondi où un centime pourrait se perdre ou s'inventer.
///
/// Un prorata — chacun sa part du montant — exigerait un arrondi, et il faudrait
/// désigner qui garde le reliquat. Aucune règle n'est non-arbitraire, et sur de
/// l'argent une règle arbitraire finit par être contestée au guichet, la note de
/// perception à la main.
///
/// ## L'ordre est porteur
///
/// Les restants arrivent dans l'ordre du DAO — échéance croissante, puis code de
/// tarif. C'est celui que la fiche affiche, et celui dans lequel une école apure
/// un arriéré : la tranche la plus ancienne se solde d'abord. La fonction ne
/// re-trie **rien** ; elle honore l'ordre reçu, et c'est à l'appelant de ne pas
/// le brouiller.
library;

/// Ce que chaque tranche reçoit, dans l'ordre où ses restants ont été donnés.
///
/// Garanties, et elles sont l'objet même de cette fonction :
///
/// ```
/// somme(résultat) == min(max(0, amountInCents), somme(restants positifs))
/// ∀i : 0 ≤ résultat[i] ≤ max(0, remainingInCents[i])
/// résultat.length == remainingInCents.length
/// ```
///
/// Un montant nul ou négatif ne distribue rien — ce n'est pas une anomalie à
/// signaler ici : la page a déjà sa propre règle sur la saisie vide, et une
/// lecture qui lèverait ferait tomber un écran d'argent pour un champ pas encore
/// rempli.
///
/// Un restant nul ou négatif reçoit **zéro et garde sa place** : le résultat est
/// aligné sur l'entrée, index par index. Escamoter ces tranches obligerait
/// l'appelant à tenir une seconde correspondance entre deux listes de longueurs
/// différentes — exactement le genre de décalage qui impute de l'argent sur la
/// mauvaise créance.
List<int> cascadeAllocation({
  required int amountInCents,
  required List<int> remainingInCents,
}) {
  var left = amountInCents > 0 ? amountInCents : 0;

  return [
    for (final remaining in remainingInCents)
      if (left <= 0 || remaining <= 0)
        0
      else
        // `left` décroît de ce qu'on vient de poser : c'est toute
        // l'arithmétique de la cascade, et elle ne quitte jamais les entiers.
        () {
          final taken = remaining < left ? remaining : left;
          left -= taken;
          return taken;
        }(),
  ];
}

/// Ce que la cascade posera au total, sans construire la répartition.
///
/// Sert à borner la saisie et à afficher « il reste tant » sans passer par la
/// liste : le plafond d'un groupe est la somme de ce que ses tranches peuvent
/// encore absorber.
int cascadeCapInCents(List<int> remainingInCents) {
  var total = 0;
  for (final remaining in remainingInCents) {
    if (remaining > 0) total += remaining;
  }
  return total;
}
