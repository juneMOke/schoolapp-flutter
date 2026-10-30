import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/ticket_print_queue_repository.dart';

/// Les tickets que ce poste doit encore imprimer (continuité RC, lot D).
class ListPendingTicketJobsUseCase {
  final TicketPrintQueueRepository _repository;

  const ListPendingTicketJobsUseCase(this._repository);

  Future<Either<Failure, List<TicketPrintJob>>> call() =>
      _repository.pendingJobs();
}

/// Le papier d'un ticket de la file est sorti.
class MarkTicketJobPrintedUseCase {
  final TicketPrintQueueRepository _repository;

  const MarkTicketJobPrintedUseCase(this._repository);

  Future<Either<Failure, Unit>> call(TicketPrintJob job) =>
      _repository.markPrinted(job);
}

/// L'envoi d'un ticket de la file a échoué ; il y reste, avec sa cause.
class RecordTicketJobProblemUseCase {
  final TicketPrintQueueRepository _repository;

  const RecordTicketJobProblemUseCase(this._repository);

  Future<Either<Failure, Unit>> call(TicketPrintJob job, String problem) =>
      _repository.recordProblem(job, problem);
}

/// Le ticket d'annulation d'un versement est sorti hors de la file.
class MarkCancellationTicketPrintedUseCase {
  final TicketPrintQueueRepository _repository;

  const MarkCancellationTicketPrintedUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String paymentId) =>
      _repository.markCancellationPrinted(paymentId);
}

/// « Relancer » : le reçu qu'un accusé n'a pas rapporté est redemandé sans
/// attendre la prochaine tentative.
class RetryTicketReceiptUseCase {
  final TicketPrintQueueRepository _repository;

  const RetryTicketReceiptUseCase(this._repository);

  Future<Either<Failure, Unit>> call(TicketPrintJob job) =>
      _repository.retryReceipt(job);
}
