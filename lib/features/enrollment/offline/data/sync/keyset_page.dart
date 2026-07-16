/// Enveloppe de pagination **keyset** partagée par les pages de pull delta
/// (contrat `openApi.yaml`, ADR-008/009). Le serveur pagine par
/// `(server_updated_at, id)` et n'expose que des jetons **opaques** (base64url) :
/// le client les renvoie VERBATIM en `cursor`, sans jamais les ré-trier ni les
/// recalculer.
///
///  - [nextCursor]    : présent SSI [hasMore] — progression DANS le cycle (page
///                      suivante). Mémorisé après chaque page pour la reprise :
///                      un device interrompu redémarre à ce jeton.
///  - [nextWatermark] : présent SSI dernière page d'un cycle NON vide — début du
///                      prochain cycle, marge de sécurité Δ déjà appliquée.
///  - [hasMore]       : `true` → d'autres pages restent dans ce cycle ; `false`
///                      → dernière page (**≠ 304**, qui, lui, n'a pas de corps).
///  - [serverTime]    : horloge serveur à la réponse (indicatif / fraîcheur).
class KeysetPageEnvelope {
  final String? nextCursor;
  final String? nextWatermark;
  final bool hasMore;
  final int? totalCount;
  final String serverTime;

  const KeysetPageEnvelope({
    this.nextCursor,
    this.nextWatermark,
    required this.hasMore,
    this.totalCount,
    required this.serverTime,
  });

  factory KeysetPageEnvelope.fromJson(Map<String, dynamic> j) =>
      KeysetPageEnvelope(
        nextCursor: j['nextCursor'] as String?,
        nextWatermark: j['nextWatermark'] as String?,
        hasMore: (j['hasMore'] as bool?) ?? false,
        totalCount: (j['totalCount'] as num?)?.toInt(),
        serverTime: j['serverTime'] as String,
      );

  /// Jeton à mémoriser après cette page : le curseur de progression tant qu'il
  /// reste des pages ([hasMore]), sinon le watermark de fin de cycle. `null` →
  /// aucun jeton à avancer (page vide en fin de cycle → on conserve le curseur
  /// mémorisé et on ne bumpe que la fraîcheur).
  String? get cursorToPersist => hasMore ? nextCursor : nextWatermark;
}

/// Contrat commun des pages keyset : liste typée + enveloppe de pagination.
/// Permet au squelette de pull (`_keysetPull`) de parcourir n'importe quelle
/// ressource paginée sans la connaître.
abstract class KeysetPageDto<I> {
  List<I> get items;
  KeysetPageEnvelope get page;
}
