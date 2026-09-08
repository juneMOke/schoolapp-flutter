import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';

/// Quand le dernier papier est-il sorti pour ce versement, sur cette tablette ?
///
/// N'AUTORISE RIEN. La réimpression est libre depuis que le ticket suit le
/// patron de la boutique : le bouton est toujours offert, et cette date sert
/// uniquement à choisir ce que la ligne dit — « Imprimer maintenant » ou
/// « Réimprimer le ticket », « Jamais imprimé depuis cette tablette » ou
/// « Imprimé le … ».
///
/// Il remplace `AwaitsTicketPrintUseCase`, qui posait la question inverse et
/// dont la réponse servait de grille d'affichage.
class TicketPrintedAtUseCase {
  final ProvisionalTicketRepository _repository;

  const TicketPrintedAtUseCase(this._repository);

  Future<DateTime?> call(String paymentId) =>
      _repository.ticketPrintedAt(paymentId);
}

/// Retient qu'un papier est **physiquement sorti** pour ce versement.
///
/// Appelé sur le seul succès thermique : c'est ce marquage qui retire le
/// rattrapage du détail du paiement, donc ce qui empêche le geste de devenir
/// une réimpression.
class MarkTicketPrintedUseCase {
  final ProvisionalTicketRepository _repository;

  const MarkTicketPrintedUseCase(this._repository);

  Future<void> call(String paymentId) =>
      _repository.markTicketPrinted(paymentId);
}
