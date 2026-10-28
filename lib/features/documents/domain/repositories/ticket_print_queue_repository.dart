import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';

/// Les tickets que ce poste doit encore imprimer (continuité RC, lot D).
abstract class TicketPrintQueueRepository {
  /// Les tickets à imprimer : prêts d'abord, par numéro de reçu, puis ceux qui
  /// attendent leur numéro, par date de saisie.
  Future<Either<Failure, List<TicketPrintJob>>> pendingJobs();

  /// Le papier de [job] est sorti.
  Future<void> markPrinted(TicketPrintJob job);

  /// L'envoi de [job] a échoué pour [problem] ; il reste dans la file.
  Future<void> recordProblem(TicketPrintJob job, String problem);

  /// Le ticket d'annulation de [paymentId] est sorti hors de la file.
  Future<void> markCancellationPrinted(String paymentId);
}
