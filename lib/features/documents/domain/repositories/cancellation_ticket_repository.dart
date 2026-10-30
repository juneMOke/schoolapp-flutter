import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';

/// Compose le ticket d'annulation d'un versement, 100 % en local
/// (continuité des tickets RC, lot B).
abstract class CancellationTicketRepository {
  /// Refuse un versement introuvable, pas encore annulé (annulation non
  /// acquittée), ou dont le reçu n'a pas de numéro définitif
  /// ([ReceiptAwaitingNumberFailure]).
  Future<Either<Failure, TicketCancellationModel>> buildForPayment({
    required String paymentId,
    required TicketCancellationLabels labels,
  });
}
