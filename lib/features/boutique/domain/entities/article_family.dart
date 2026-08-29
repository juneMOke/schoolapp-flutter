/// La famille d'un article du catalogue.
///
/// **L'ordre de déclaration EST l'ordre d'affichage** des groupes du catalogue,
/// jamais l'alphabet ni le volume de ventes — et c'est l'ordre du serveur
/// (`ArticleFamily` côté back), recopié tel quel. Réordonner ces constantes
/// réordonne le catalogue de toutes les caisses.
///
/// Elle porte quatre choses à l'écran, et aucune n'est cosmétique : l'ordre des
/// groupes, le découpage en sections, les filtres — seule navigation praticable
/// au-delà de quelques dizaines d'articles — et l'accent de couleur du
/// médaillon.
enum ArticleFamily {
  /// Polos, chemises, écussons, survêtements — ce qui se porte.
  uniforme('UNIFORME'),

  /// Journal de classe, bulletins, fournitures. Fourre-tout assumé du catalogue.
  fournitures('FOURNITURES'),

  /// Promenades, sorties, activités parascolaires.
  activites('ACTIVITES'),

  /// Retrait de dossier et autres actes administratifs payants.
  actes('ACTES');

  const ArticleFamily(this.wire);

  /// Valeur stockée en base et servie sur le fil. Un renommage imposerait une
  /// migration serveur : ce n'est pas un libellé d'affichage.
  final String wire;

  /// Résout une valeur servie.
  ///
  /// Rend `null` sur l'inconnu plutôt que de replier sur une famille par
  /// défaut : ranger d'office un article inconnu sous « Fournitures » lui
  /// donnerait une place et une couleur que personne n'a choisies, et masquerait
  /// un catalogue servi par un serveur plus récent que ce client.
  static ArticleFamily? fromWire(Object? wire) {
    if (wire is! String || wire.isEmpty) return null;
    for (final family in values) {
      if (family.wire == wire) return family;
    }
    return null;
  }
}
