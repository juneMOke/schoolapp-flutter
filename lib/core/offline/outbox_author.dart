/// Attribution d'une écriture d'outbox à son AUTEUR, sur tablette partagée.
///
/// ## Le problème
///
/// La file d'outbox est unique et globale : elle ne connaît ni compte ni école
/// au moment du flush. Sur une tablette que plusieurs enseignants se passent,
/// les écritures hors ligne de l'un partent donc avec le jeton de l'autre. Le
/// serveur refuse (`SyncAttributionGuard` compare l'`authorId` du corps au
/// claim `uid` du JWT), et le sort de l'écriture dépend alors du handler :
/// trois d'entre eux savaient reconnaître ce refus, quatre non — et pour
/// l'inscription, où un `403` est classé terminal, l'écriture du collègue
/// était **brûlée** en `SYNC_ERROR` sans aucun chemin de retour (son unique
/// site d'enfilage exige que le dossier soit encore `DRAFT`).
///
/// ## Le choix
///
/// L'auteur n'est pas une colonne de la table : il vit à la RACINE du payload
/// figé, sous la clé [kOutboxAuthorIdKey], estampillé à la SAISIE (ADR-010
/// D-05) — donc exactement la valeur que le serveur comparera. Le lire depuis
/// le payload plutôt que depuis une colonne dédiée évite toute possibilité de
/// désynchronisation entre ce que le client filtre et ce que le serveur
/// vérifie : c'est la même chaîne d'octets.
///
/// Contrepartie assumée : un décodage JSON par entrée à chaque flush, et les
/// entrées d'autrui restent sélectionnées puis reportées. C'est sans effet sur
/// une file de taille normale ; le jour où elle grossit, la parade est une
/// colonne `author_uid` + un filtre de sélection (délibérément remis à plus
/// tard, cf. la décision consignée dans le message de commit).
library;

import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_entry.dart';

/// Clé RACINE de l'auteur dans tout payload d'outbox. Les sept agrégats la
/// posent (elle est simplement omise quand l'uid est inconnu), et le serveur la
/// lit au même endroit. Constante pour qu'un renommage casse à la compilation
/// plutôt qu'en silence.
const String kOutboxAuthorIdKey = 'authorId';

/// Auteur non attribuable : payload sans `authorId` (session héritée sans claim
/// `uid`), ou payload illisible.
///
/// **Traité comme « appartient à tout le monde »**, jamais comme « appartient à
/// personne » : une entrée sans auteur ne pourrait être réclamée par aucun
/// compte, donc la geler l'orphelinerait à vie. Elle part donc comme avant, et
/// c'est le serveur qui tranchera — un refus VISIBLE valant mieux qu'un gel
/// silencieux.
const String kUnattributedOutboxAuthor = '';

/// Auteur d'un payload d'outbox figé, ou [kUnattributedOutboxAuthor].
///
/// **Ne lève jamais** : un payload illisible ne doit pas faire échouer un
/// flush. Un payload dont on ne sait rien est non attribué, donc poussable —
/// même politique que l'absence de clé.
String outboxAuthorUidOf(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) return kUnattributedOutboxAuthor;
    final value = decoded[kOutboxAuthorIdKey];
    return value is String && value.isNotEmpty
        ? value
        : kUnattributedOutboxAuthor;
  } catch (_) {
    return kUnattributedOutboxAuthor;
  }
}

/// Vrai si [payload] appartient à un compte identifié AUTRE que [currentUid] —
/// seul cas où pousser est certain d'échouer côté serveur.
///
/// Faux dès qu'un des deux côtés est inconnu : porteur sans `uid` (backend
/// hérité sans le claim) ou entrée non attribuée. Le doute profite toujours à
/// l'envoi : bloquer une écriture qui aurait pu partir est un dommage
/// silencieux, la laisser partir produit au pire un refus visible.
bool isForeignOutboxAuthor(String payload, String? currentUid) {
  if (currentUid == null || currentUid.isEmpty) return false;
  final author = outboxAuthorUidOf(payload);
  if (author == kUnattributedOutboxAuthor) return false;
  return author != currentUid;
}

/// Ce qu'il reste en file au nom d'AUTRES comptes — de quoi l'afficher sans
/// jamais en révéler le contenu.
class OtherAuthorsPending {
  /// Nombre d'entrées en attente appartenant à d'autres comptes identifiés.
  final int count;

  /// Epoch ms de la plus ancienne d'entre elles (`null` si [count] vaut 0).
  final int? oldestCreatedAt;

  /// Uids des comptes concernés, ordre d'apparition (le plus souvent un seul).
  final List<String> authorUids;

  const OtherAuthorsPending({
    required this.count,
    required this.oldestCreatedAt,
    required this.authorUids,
  });

  static const OtherAuthorsPending none = OtherAuthorsPending(
    count: 0,
    oldestCreatedAt: null,
    authorUids: <String>[],
  );

  bool get isEmpty => count == 0;
}

/// Agrège les entrées de [entries] qui appartiennent à un autre compte que
/// [currentUid]. Fonction PURE : la lecture de la file reste au DAO.
OtherAuthorsPending summarizeOtherAuthors(
  Iterable<OutboxEntry> entries,
  String? currentUid,
) {
  var count = 0;
  int? oldest;
  final uids = <String>[];
  for (final entry in entries) {
    if (!isForeignOutboxAuthor(entry.payload, currentUid)) continue;
    count++;
    if (oldest == null || entry.createdAt < oldest) oldest = entry.createdAt;
    final author = outboxAuthorUidOf(entry.payload);
    if (!uids.contains(author)) uids.add(author);
  }
  return count == 0
      ? OtherAuthorsPending.none
      : OtherAuthorsPending(
          count: count,
          oldestCreatedAt: oldest,
          authorUids: uids,
        );
}
