import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/ticket_print_queue_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_queue_cubit.dart';

/// Une file de tickets vide : le bandeau « Tickets à imprimer » (continuité
/// des tickets RC, lot D) se monte sans rien afficher.
///
/// Pour les écrans qui le portent — tableau de bord Finances, Facturation —
/// et dont le test ne parle pas de tickets.
void stubEmptyTicketsToPrint() {
  if (getIt.isRegistered<TicketPrintQueueCubit>()) return;
  getIt.registerFactory<TicketPrintQueueCubit>(
    () => TicketPrintQueueCubit(
      ListPendingTicketJobsUseCase(_EmptyQueue()),
      RetryTicketReceiptUseCase(_EmptyQueue()),
    ),
  );
}

void unstubTicketsToPrint() {
  if (getIt.isRegistered<TicketPrintQueueCubit>()) {
    getIt.unregister<TicketPrintQueueCubit>();
  }
}

class _EmptyQueue implements TicketPrintQueueRepository {
  @override
  Future<Either<Failure, List<TicketPrintJob>>> pendingJobs() async =>
      const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
