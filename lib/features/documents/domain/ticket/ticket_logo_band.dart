import 'dart:typed_data';

/// Le logo de l'école, tel qu'il se pose en tête du ticket.
///
/// ## Pourquoi cette bande ne passe PAS par le gabarit
///
/// `TicketTextLayout` produit une `List<String>`, et c'est ce pivot qui rend
/// vérifiable le critère d'acceptation de l'ADR — « même contenu textuel entre
/// les deux sorties », contrôlable par une simple comparaison de chaînes. Une
/// image n'y entre pas.
///
/// Elle est donc posée **par chaque renderer**, en amont du texte, sur le
/// précédent que `PdfTicketRenderer` a déjà établi pour la consigne de découpe :
/// ce qui appartient au SUPPORT est placé par le renderer, jamais par le
/// gabarit. Le corps de texte reste identique avec ou sans logo, donc les tests
/// d'égalité entre sorties tiennent sans qu'une ligne soit touchée — et le
/// gabarit peut continuer d'évoluer sans jamais reposer la question du logo.
///
/// ## Une seule source, deux dérivations
///
/// La bande ne porte que ses **points**, et les deux renderers en dérivent ce
/// dont ils ont besoin : le flux ESC/POS les inverse et les verse dans
/// `GS v 0`, le PDF les étend en pixels. Porter en plus les octets PNG
/// d'origine aurait ouvert la possibilité que les deux sorties montrent des
/// images différentes — exactement ce que le pivot unique évite pour le texte.
class TicketLogoBand {
  /// Largeur en points. **Multiple de 8** — c'est l'unité de `GS v 0`, qui
  /// compte sa largeur en octets — et au plus [maxWidthDots].
  final int widthDots;

  /// Hauteur en points. À 203 dpi (8 points/mm), elle se paie en papier à
  /// **chaque** impression : 128 points valent 16 mm de rouleau par ticket.
  final int heightDots;

  /// Les points, **8 par octet, bit de poids fort à gauche**, ligne par ligne.
  ///
  /// ⚠️ **Convention PNG : `1` = BLANC, `0` = encre.** C'est celle du fichier
  /// servi, et elle est l'inverse de celle d'ESC/POS, où un bit à 1 est un point
  /// IMPRIMÉ. L'inversion vit dans le renderer ESC/POS, seule brique qui connaît
  /// `GS v 0` — le serveur ne livre jamais d'octets pré-inversés.
  ///
  /// Versés tels quels dans la commande, ces octets sortiraient un rectangle
  /// noir portant le sceau en réserve blanche.
  final Uint8List bits;

  const TicketLogoBand({
    required this.widthDots,
    required this.heightDots,
    required this.bits,
  });

  /// Largeur maximale d'une bande sur un rouleau 80 mm à 203 dpi : 576 points,
  /// soit 72 mm. C'est un **plafond**, pas une cible — un logo carré posé à
  /// cette largeur ferait 576 points de haut, donc 72 mm de papier par ticket.
  static const int maxWidthDots = 576;

  /// Nombre d'octets par ligne de points.
  int get bytesPerRow => widthDots ~/ 8;

  /// La bande est-elle exploitable telle quelle ?
  ///
  /// Trois conditions, et chacune produirait un défaut différent si elle était
  /// supposée : une largeur non multiple de 8 décalerait chaque ligne d'un
  /// fragment d'octet, une largeur au-delà du plafond déborderait la tête
  /// d'impression, et un tableau d'une autre taille ferait lire la commande
  /// au-delà de ses données.
  bool get isUsable =>
      widthDots > 0 &&
      heightDots > 0 &&
      widthDots % 8 == 0 &&
      widthDots <= maxWidthDots &&
      bits.length == bytesPerRow * heightDots;
}
