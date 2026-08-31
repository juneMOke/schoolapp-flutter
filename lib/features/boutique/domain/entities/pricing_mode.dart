/// Comment le prix d'un article se résout.
///
/// **Déclaré, jamais inféré des valeurs** (invariant I-1). C'est la seule chose
/// qui dise à la caisse si elle doit demander un niveau, et la déduire de la
/// forme des prix se trompe dans les deux sens :
///
///  - chez La Fontaine, la Lacoste vaut 10 en primaire ET 10 en CTEB. Qui lirait
///    les chiffres conclurait « c'est plat », puis la vendrait au tarif primaire
///    en humanités, où elle vaut 15 ;
///  - l'écusson vaut 10 lui aussi, et il est vraiment plat. Rien dans les
///    montants ne distingue les deux cas.
///
/// Lire un prix n'apprend rien sur la façon dont ce prix a été décidé.
enum PricingMode {
  /// Un montant unique, quel que soit le niveau — et sans qu'aucun niveau
  /// n'entre dans le calcul.
  prixUnique('PRIX_UNIQUE'),

  /// Une grille : un montant par niveau. La vente exige donc un bénéficiaire
  /// (dont le niveau se déduit) ou un niveau choisi au guichet.
  prixParNiveau('PRIX_PAR_NIVEAU');

  const PricingMode(this.wire);

  final String wire;

  /// Résout une valeur servie, `null` sur l'inconnu.
  ///
  /// Aucun repli : un article dont le mode est illisible ne doit surtout pas
  /// passer pour un prix unique — il se vendrait sans qu'on demande le niveau,
  /// donc au mauvais tarif.
  static PricingMode? fromWire(Object? wire) {
    if (wire is! String || wire.isEmpty) return null;
    for (final mode in values) {
      if (mode.wire == wire) return mode;
    }
    return null;
  }
}
