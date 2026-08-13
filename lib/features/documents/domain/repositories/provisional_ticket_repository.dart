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

  /// Vrai si un papier est déjà sorti de CE poste pour ce versement.
  Future<bool> hasPrintedTicket(String paymentId);

  /// Vrai si ce versement **attend encore son premier papier**, sur cette
  /// tablette.
  ///
  /// Ce n'est PAS une réimpression, et la nuance décide de tout : ADR-013
  /// interdit de ressortir un ticket déjà remis, pas de rattraper un tirage qui
  /// n'a jamais abouti. D'où deux conditions, tenues ici plutôt qu'à l'écran
  /// parce qu'elles sont métier :
  ///
  /// * **aucun papier n'est sorti** — la trace se pose sur le seul succès
  ///   thermique, donc un repli PDF laisse le rattrapage ouvert ;
  /// * **le versement a été encaissé sur CETTE tablette** — ailleurs, le ticket
  ///   sortirait dégradé de façon visible pour le parent : sans référence
  ///   provisoire locale, la « Réf. » retombe sur un UUID de 36 caractères, et
  ///   les libellés de répartition sur les codes de frais bruts.
  ///
  /// L'annulation du reçu, elle, se juge à l'écran : c'est lui qui la connaît.
  Future<bool> awaitsTicketPrint(String paymentId);
}
