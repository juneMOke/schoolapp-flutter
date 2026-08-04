import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';

/// Compose le reçu provisoire d'un encaissement, 100 % en local.
class BuildProvisionalTicketUseCase {
  final ProvisionalTicketRepository _repository;

  const BuildProvisionalTicketUseCase(this._repository);

  Future<Either<Failure, TicketReceiptModel>> call({
    required String paymentId,
    required TicketLabels labels,
  }) => _repository.buildForPayment(paymentId: paymentId, labels: labels);
}
