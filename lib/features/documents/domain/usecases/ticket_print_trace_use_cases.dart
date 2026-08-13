import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';

/// Ce versement attend-il encore son premier papier, sur cette tablette ?
///
/// Sépare deux gestes que le guichet ne doit surtout pas confondre : **rattraper
/// un tirage qui n'a jamais abouti** — ce que l'ADR-013 n'interdit pas — et
/// **réimprimer un ticket déjà remis**, qu'il interdit explicitement en V1. La
/// règle qui les distingue vit dans le repository ; ce cas d'usage n'existe que
/// pour que la présentation ne parle jamais à la couche de données.
class AwaitsTicketPrintUseCase {
  final ProvisionalTicketRepository _repository;

  const AwaitsTicketPrintUseCase(this._repository);

  Future<bool> call(String paymentId) =>
      _repository.awaitsTicketPrint(paymentId);
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
