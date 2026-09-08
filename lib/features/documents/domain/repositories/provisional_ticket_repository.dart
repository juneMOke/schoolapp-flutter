import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';

/// Compose le reçu provisoire d'un encaissement à partir du **seul local**.
///
/// Aucun appel réseau : c'est toute la raison d'être du ticket (ADR-012 D-3).
/// Un parent qui verse des espèces repart avec un papier, coupure réseau ou non.
abstract class ProvisionalTicketRepository {
  /// [labels] porte les chaînes traduites — le modèle et son gabarit restent
  /// purs, sans `BuildContext`.
  ///
  /// `NotFoundFailure` si le paiement est introuvable en local : c'est le seul
  /// cas où l'on refuse d'imprimer. Tout le reste (école, classe, matricule,
  /// caissier) est **optionnel** et simplement tu.
  Future<Either<Failure, TicketReceiptModel>> buildForPayment({
    required String paymentId,
    required TicketLabels labels,
  });

  /// Retient qu'un papier est **physiquement sorti** pour ce versement.
  ///
  /// ⚠️ N'est appelé qu'après une impression **thermique** réussie. Le repli PDF
  /// rend la main dès que le spouleur a accepté le document, et le caissier peut
  /// encore annuler la boîte système ou choisir « Enregistrer en PDF » : marquer
  /// sur ce signal déclarerait servi un ticket qui n'existe pas.
  ///
  /// Ne remonte jamais d'erreur. Perdre la trace fait au pire réapparaître le
  /// rattrapage sur un versement déjà servi ; la faire échouer bruyamment
  /// ferait croire à un échec d'impression alors que le papier est dans la main
  /// du parent.
  Future<void> markTicketPrinted(String paymentId);

  /// Quand un papier est sorti de CE poste pour ce versement, `null` si aucun.
  ///
  /// **Ce n'est plus une grille d'autorisation.** La réimpression est libre —
  /// le bouton est toujours offert, sur le patron de la boutique — et cette
  /// date ne décide plus de rien : elle dit ce que la ligne d'écran AFFICHE,
  /// « Imprimer maintenant » ou « Réimprimer le ticket ».
  ///
  /// C'est la DERNIÈRE impression et non la première : la trace est réécrite à
  /// chaque tirage thermique réussi. Un caissier qui lit « Imprimé le … » doit
  /// pouvoir s'y fier pour savoir quand le dernier papier est sorti.
  ///
  /// ## Ce qui a disparu avec elle
  ///
  /// `awaitsTicketPrint` posait deux conditions : aucun papier sorti, et
  /// versement encaissé sur CETTE tablette. La première est devenue un
  /// affichage, la seconde n'a plus d'objet — un versement descendu par pull
  /// compose désormais une pièce entière (référence de repli, attribution
  /// serveur, libellés du référentiel), ce que
  /// `provisional_ticket_composition_test.dart` constate sur la pièce elle-même.
  ///
  /// L'annulation du reçu, elle, se juge toujours à l'écran : c'est lui qui la
  /// connaît, et un reçu retiré ne ressort jamais en ticket.
  Future<DateTime?> ticketPrintedAt(String paymentId);
}
