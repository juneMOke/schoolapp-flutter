/// Force du rapprochement entre l'identité saisie au guichet et un élève déjà
/// connu de la tablette.
///
/// L'ordre de déclaration **est** le classement : `index` croissant = de moins
/// en moins sûr. Un tri par `index` remonte donc d'abord ce qui mérite le plus
/// l'attention.
///
/// Aucun de ces niveaux ne conclut. Même [certain] reste un avertissement : la
/// sonde ne barre jamais la route à une inscription.
enum EnrollmentDuplicateLevel {
  /// Les trois noms identiques, position par position, **et** la même date de
  /// naissance. La re-saisie pure.
  certain,

  /// Les mêmes noms, mais **pas dans le même ordre**, et la même date de
  /// naissance. C'est l'inversion nom ↔ post-nom, l'erreur de guichet la plus
  /// courante — un post-nom porté comme nom sur un dossier, l'inverse sur
  /// l'autre. Couvre aussi le dossier historique **sans post-nom**, dont les
  /// deux noms se retrouvent tels quels dans la saisie.
  probable,

  /// Les noms correspondent, la **date de naissance diverge** — ou ne se lit
  /// pas. Année devinée, jour et mois intervertis, date absente d'un dossier
  /// ancien. C'est aussi le niveau des vrais homonymes : il informe, il ne
  /// conclut pas.
  possible,
}
