/// L'URL de vérification d'un reçu scellé — celle que porte le QR du PDF, et
/// désormais celle du ticket (révision de D-4, 2026-10-30).
///
/// Elle arrive par trois chemins (accusés `documents[].verificationUrl`, delta
/// éditique, en-tête `X-Document-Verification-Url`) et ne s'imprime qu'en QR :
/// une valeur douteuse doit donc tomber À L'ENTRÉE, pas sur le papier. Un QR
/// qui mène ailleurs que chez le serveur de l'école se scanne avec la même
/// confiance qu'un vrai.
abstract final class ReceiptVerificationUrl {
  /// Au-delà, le QR grossit sans raison sur 80 mm ; une URL de vérification
  /// tient en une centaine de caractères.
  static const int maxLength = 512;

  /// L'URL si elle est absolue, en `https`, munie d'un hôte et sans
  /// identifiants ; `null` sinon — et `null` aussi pour une valeur qui n'est
  /// pas une chaîne, sans jamais lever (l'accusé est money-grade).
  ///
  /// - **`https` seulement**, la règle d'`API_BASE_URL` hors dev : un QR en
  ///   clair se laisse détourner sur le réseau du parent qui le scanne. Un
  ///   serveur de dev en `http` donne donc des tickets sans QR.
  /// - **Aucun identifiant** : `https://api.eteelo.com@ailleurs.example/…`
  ///   se lit « eteelo » à l'œil et mène à `ailleurs.example`.
  ///
  /// L'hôte n'est pas comparé à celui de l'API : la page de vérification peut
  /// vivre sur un domaine public distinct.
  static String? normalize(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty || text.length > maxLength) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    if (uri.userInfo.isNotEmpty) return null;
    return text;
  }
}
