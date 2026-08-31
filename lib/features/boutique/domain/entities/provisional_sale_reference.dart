/// La référence d'une vente **avant** que son reçu ne soit scellé.
///
/// **Une seule définition**, et c'est la raison de ce fichier : le ticket
/// imprimé et le bandeau de l'écran la posent tous les deux, et deux calculs
/// divergeraient — le papier dirait un numéro, l'écran un autre, sur la même
/// vente. Un client qui les compare n'aurait aucun moyen de savoir lequel citer.
abstract final class ProvisionalSaleReference {
  /// Préfixe conventionnel du dépôt pour une pièce non scellée.
  static const String prefix = 'PROV-';

  /// Nombre de caractères retenus de l'identifiant : assez pour retrouver la
  /// vente au support, assez court pour tenir sur un rouleau de 48 colonnes.
  static const int idLength = 8;

  static String of(String saleId) {
    final compact = saleId.replaceAll('-', '');
    final head = compact.length <= idLength
        ? compact
        : compact.substring(0, idLength);
    return '$prefix${head.toUpperCase()}';
  }
}
