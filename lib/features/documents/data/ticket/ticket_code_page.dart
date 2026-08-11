/// Page de code ESC/POS — la table par laquelle l'imprimante interprète les
/// octets qu'on lui envoie.
///
/// ## Pourquoi cette indirection existe
///
/// `TicketCharset.printable()` ramène tout texte au **Latin-1** : chaque
/// caractère y tient sur un octet, et « Sacré-Cœur » devient « Sacré-Coeur ».
/// Mais une thermique ne lit pas du Latin-1 : elle lit la page de code
/// **actuellement sélectionnée**, et la plupart démarrent en CP437, où l'octet
/// `0xE9` n'est pas `é` mais `Ú`.
///
/// ✅ **Tranché au papier le 2026-08-11 : la NT-8003DD supporte WPC1252**
/// (`ESC t 16`), constaté en imprimant la même ligne accentuée sous cinq
/// sélecteurs candidats et en lisant lequel sortait juste. C'est le cas idéal :
/// CP1252 est identique au Latin-1 sur toute la plage `0xA0–0xFF`, donc la
/// sortie de `TicketCharset` part **octet pour octet, sans aucune table**.
///
/// ⚠️ **Aucune page autre que [cp1252] n'est fournie ici, et c'est délibéré.**
/// Une table écrite d'après une documentation, sans papier pour la contredire,
/// est une table qu'on croit juste : elle produirait des accents faux avec
/// l'assurance d'un test vert. Si un autre modèle d'imprimante entre au parc et
/// ne propose qu'une page plus ancienne, ses correspondances se déclarent dans
/// [overrides] — et se vérifient par [probe], au papier, jamais sur fiche
/// technique.
class TicketCodePage {
  /// `n` de la commande `ESC t n`.
  final int selector;

  /// Nom lisible — n'apparaît jamais sur le ticket, seulement dans le banc de
  /// test et les messages de diagnostic.
  final String debugName;

  /// Correspondances `point de code Latin-1 → octet`, pour les seules valeurs
  /// où la page cible diverge du Latin-1. Une valeur absente de la page se
  /// déclare ici vers `0x3F` (`?`) : un caractère visiblement manquant se
  /// corrige, un caractère faux se croit juste.
  final Map<int, int> overrides;

  const TicketCodePage({
    required this.selector,
    required this.debugName,
    this.overrides = const <int, int>{},
  });

  /// Windows-1252 — **la page du parc**, confirmée au papier : identité sur
  /// toute la plage utile, donc zéro correspondance à maintenir.
  ///
  /// CP1252 ne diverge du Latin-1 que sur `0x80–0x9F`, plage que
  /// `TicketCharset` n'émet jamais (elle y translittère `€`, `’`, `—`… en
  /// ASCII) et que [encode] refuse de toute façon comme domaine de commandes.
  static const TicketCodePage cp1252 = TicketCodePage(
    selector: 16,
    debugName: 'WPC1252',
  );

  /// Page arbitraire, en identité — l'outil de la sonde.
  ///
  /// Envoyer les **mêmes** octets Latin-1 sous plusieurs sélecteurs et lire
  /// lequel sort juste est la seule façon honnête d'apprendre ce que le
  /// matériel supporte : c'est le papier qui répond, pas la fiche technique.
  factory TicketCodePage.probe(int selector) =>
      TicketCodePage(selector: selector, debugName: 'ESC t $selector');

  /// Octet à écrire sur le fil pour [latin1].
  int encode(int latin1) => overrides[latin1] ?? latin1;
}
