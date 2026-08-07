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
}
