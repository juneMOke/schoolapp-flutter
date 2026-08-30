import 'package:equatable/equatable.dart';

/// Une vente telle que l'historique la montre : ce que le guichet a encaissé, à
/// qui, quand, et si le serveur le sait.
///
/// **Lue en local, exclusivement.** Une caisse se consulte le jour où le réseau
/// manque ; interroger le serveur ferait dépendre du réseau la vérification de
/// ce qu'on vient d'encaisser.
class SaleHistoryEntry extends Equatable {
  final String id;

  /// Le nom composé quand le serveur l'a renvoyé, le nom saisi sinon — jamais
  /// recomposé à partir des trois champs : « Ndombo Lelo Willy » ne se
  /// redécoupe pas sans se tromper, et le recomposer inventerait un ordre.
  final String payerName;

  final String? payerPhoneNumber;
  final int totalInCents;
  final String currency;

  /// Horodatage **métier** de la vente, en ISO-8601 UTC. Une vente saisie hors
  /// ligne le lundi et synchronisée le mercredi appartient à la caisse du lundi.
  final String soldAt;

  /// Le numéro du reçu scellé, `null` tant que le serveur ne l'a pas rendu.
  ///
  /// C'est la seule marque fiable de l'état d'une vente vis-à-vis du serveur —
  /// et ce que le guichet cherche quand un parent revient avec son ticket.
  final String? receiptNumber;

  /// Où en est la vente vis-à-vis du serveur : `PENDING_SYNC`, `SYNCED`,
  /// `FAILED`. Affiché tel quel serait du jargon ; l'écran le traduit.
  final String syncStatus;

  /// Somme des quantités des lignes — ce que le client est reparti avec.
  final int articleCount;

  const SaleHistoryEntry({
    required this.id,
    required this.payerName,
    required this.totalInCents,
    required this.currency,
    required this.soldAt,
    required this.syncStatus,
    required this.articleCount,
    this.payerPhoneNumber,
    this.receiptNumber,
  });

  /// La vente est-elle encore en attente de départ ?
  bool get isPending => syncStatus == 'PENDING_SYNC';

  @override
  List<Object?> get props => [
    id,
    payerName,
    payerPhoneNumber,
    totalInCents,
    currency,
    soldAt,
    receiptNumber,
    syncStatus,
    articleCount,
  ];
}
