import 'dart:convert';

/// Décodage **best-effort** des claims d'un JWT (payload base64url, non vérifié).
///
/// La signature est HS256 symétrique (ADR-010 §0.2) : le device ne peut pas la
/// vérifier. On lit donc les claims du token stocké — la confiance vient de
/// l'origine authentique (login online) + du store chiffré, pas d'une vérif
/// locale de signature. Toujours tolérant : jamais d'exception, `null` si illisible.
class JwtClaims {
  const JwtClaims._();

  /// Retourne le payload décodé du JWT, ou `null` si le token est mal formé.
  static Map<String, dynamic>? payload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(decoded);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  /// Claim `uid` (UUID serveur, ADR-010 §0.2). `null` si absent/illisible.
  static String? uid(String token) {
    final value = payload(token)?['uid'];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Vrai si le token porte un `exp` (secondes epoch) strictement futur.
  static bool isNotExpired(String token, {DateTime? now}) {
    final exp = payload(token)?['exp'];
    if (exp is! num) return false;
    final nowSeconds = (now ?? DateTime.now()).millisecondsSinceEpoch / 1000;
    return exp > nowSeconds;
  }
}
