import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/ticket_print_queue_dao.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/ticket_print_queue_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';

/// La file des tickets, lue sur la base locale (continuité RC, lot D).
///
/// L'état d'un ticket se COMPOSE ici, à chaque lecture : la ligne de file ne
/// sait que ce qui est dû ; le versement, sa correction et le reçu disent ce
/// qui est possible. Un pull qui scelle un reçu après coup rend donc son
/// ticket prêt sans que personne n'ait à le prévenir.
class TicketPrintQueueRepositoryImpl implements TicketPrintQueueRepository {
  final TicketPrintQueueDao _queue;
  final ProvisionalTicketDao _tickets;
  final PaymentReceiptResolver _receipts;
  final DateTime Function() _now;

  TicketPrintQueueRepositoryImpl({
    required TicketPrintQueueDao queue,
    required ProvisionalTicketDao tickets,
    required PaymentReceiptResolver receipts,
    DateTime Function()? now,
  }) : _queue = queue,
       _tickets = tickets,
       _receipts = receipts,
       _now = now ?? DateTime.now;

  @override
  Future<Either<Failure, List<TicketPrintJob>>> pendingJobs() async {
    try {
      final jobs = <TicketPrintJob>[];
      for (final row in await _queue.pendingRows()) {
        final job = await _jobOf(row);
        if (job != null) jobs.add(job);
      }
      jobs.sort(_byReadinessThenNumber);
      return Right(jobs);
    } catch (e) {
      return Left(StorageFailure('File des tickets illisible : $e'));
    }
  }

  /// `null` : plus aucun papier n'est dû pour cette ligne.
  Future<TicketPrintJob?> _jobOf(TicketPrintJobRow row) async {
    final cancellation = !row.isReceipt;
    if (cancellation) {
      // Une annulation refusée n'annule rien ; une origine jamais acceptée
      // (R2) n'a jamais eu de numéro. Ni l'une ni l'autre ne s'imprime.
      final status = row.correctionStatus;
      if (status == null ||
          status == PaymentCorrectionStatus.rejected ||
          status == PaymentCorrectionStatus.localOnly) {
        return null;
      }
    } else if (row.hasLiveCorrection || row.paymentCancelledAt != null) {
      // Le versement est annulé, ou en passe de l'être : son papier sera le
      // ticket d'annulation, s'il en faut un.
      return null;
    }

    final receipt = await _receipts.resolve(row.paymentId);
    // Retiré par un autre poste : aucun papier ne doit plus l'attester.
    if (!cancellation && receipt.isCancelled) return null;

    final numbered =
        receipt.status == PaymentReceiptStatus.definitive &&
        (receipt.number?.trim().isNotEmpty ?? false);
    final ready = cancellation
        // L'annulation doit être ACQUITTÉE : le ticket dit qu'elle a eu lieu.
        ? numbered && row.correctionStatus == PaymentCorrectionStatus.applied
        : numbered;

    final student = await _tickets.findStudent(
      (await _tickets.findPayment(row.paymentId))?.studentId ?? '',
    );
    final tenders = await _tickets.findTenders(row.paymentId);

    return TicketPrintJob(
      id: row.id,
      paymentId: row.paymentId,
      kind: cancellation
          ? TicketPrintJobKind.cancellation
          : TicketPrintJobKind.receipt,
      state: ready
          ? TicketPrintJobState.ready
          : TicketPrintJobState.awaitingNumber,
      receiptNumber: numbered ? receipt.number : null,
      studentFullName: student?.fullName ?? '',
      amount: MoneyBag.of([
        for (final t in tenders) Money.parse(t.amountInCents, t.currency),
      ]),
      enteredAt:
          DateTime.tryParse(row.paidAt) ??
          DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      lastProblem: row.lastProblem,
    );
  }

  /// Prêts d'abord, dans l'ordre des numéros — c'est l'ordre de la pile du
  /// promoteur ; puis ceux qui attendent, par date de saisie.
  static int _byReadinessThenNumber(TicketPrintJob a, TicketPrintJob b) {
    if (a.isReady != b.isReady) return a.isReady ? -1 : 1;
    if (a.isReady) {
      final byNumber = a.receiptNumber!.compareTo(b.receiptNumber!);
      if (byNumber != 0) return byNumber;
      // Un même numéro : le ticket avant son annulation.
      return a.kind.index.compareTo(b.kind.index);
    }
    return a.enteredAt.compareTo(b.enteredAt);
  }

  @override
  Future<void> markPrinted(TicketPrintJob job) => _queue.markPrinted(
    jobId: job.id,
    paymentId: job.paymentId,
    isReceipt: job.kind == TicketPrintJobKind.receipt,
    nowMs: _now().millisecondsSinceEpoch,
  );

  @override
  Future<void> recordProblem(TicketPrintJob job, String problem) =>
      _queue.recordProblem(job.id, problem);

  @override
  Future<void> markCancellationPrinted(String paymentId) =>
      _queue.markCancellationPrinted(paymentId, _now().millisecondsSinceEpoch);
}
