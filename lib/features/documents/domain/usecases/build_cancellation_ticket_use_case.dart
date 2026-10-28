import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/cancellation_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';

/// Compose le ticket d'annulation d'un versement, 100 % en local.
class BuildCancellationTicketUseCase {
  final CancellationTicketRepository _repository;

  const BuildCancellationTicketUseCase(this._repository);

  Future<Either<Failure, TicketCancellationModel>> call({
    required String paymentId,
    required TicketCancellationLabels labels,
  }) => _repository.buildForPayment(paymentId: paymentId, labels: labels);
}
