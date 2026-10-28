import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/documents/data/local/cancellation_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/cancellation_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';

class CancellationTicketRepositoryImpl implements CancellationTicketRepository {
  final ProvisionalTicketDao _tickets;
  final CancellationTicketDao _cancellations;
  final PaymentReceiptResolver _receipts;

  const CancellationTicketRepositoryImpl({
    required ProvisionalTicketDao tickets,
    required CancellationTicketDao cancellations,
    required PaymentReceiptResolver receipts,
  }) : _tickets = tickets,
       _cancellations = cancellations,
       _receipts = receipts;

  @override
  Future<Either<Failure, TicketCancellationModel>> buildForPayment({
    required String paymentId,
    required TicketCancellationLabels labels,
  }) async {
    try {
      final payment = await _tickets.findPayment(paymentId);
      final cancellation = await _cancellations.find(paymentId);
      if (payment == null || cancellation == null) {
        return const Left(
          NotFoundFailure('Encaissement introuvable en local.'),
        );
      }
      final cancelledAt = cancellation.cancelledAt;
      // Le ticket affirme une annulation : il attend qu'elle soit acquittée.
      if (cancelledAt == null) {
        return const Left(
          ValidationFailure('Annulation pas encore acquittée : pas de ticket.'),
        );
      }
      final receipt = await _receipts.resolve(paymentId);
      final number = receipt.number?.trim() ?? '';
      if (!receipt.isDefinitive || number.isEmpty) {
        return const Left(ReceiptAwaitingNumberFailure());
      }

      final student = await _tickets.findStudent(payment.studentId);
      final school = await _tickets.findSchool();
      final classroomName = await _tickets.findClassroomName(
        studentId: payment.studentId,
        academicYearId: payment.academicYearId,
      );
      final tenders = await _tickets.findTenders(paymentId);
      final code = cancellation.reasonCode;

      return Right(
        TicketCancellationModel(
          schoolName: school?.name ?? '',
          schoolAddress: school?.address,
          schoolLocality: school?.locality,
          schoolEmail: school?.email,
          schoolPhone: school?.phone,
          schoolTillPhone: school?.tillPhone,
          receiptNumber: number,
          // Même lecture que le ticket de caisse : l'heure du guichet.
          originalPaidAt: (DateTime.tryParse(payment.paidAt) ?? DateTime.now())
              .toLocal(),
          studentFullName: student?.fullName ?? '',
          classroomName: classroomName,
          amount: MoneyBag.of([
            for (final t in tenders) Money.parse(t.amountInCents, t.currency),
          ]),
          cancelledAt: DateTime.fromMillisecondsSinceEpoch(cancelledAt),
          // Un code inconnu de cette version s'imprime tel quel plutôt que de
          // laisser la ligne vide.
          reason: (code == null ? null : labels.reasons[code]) ?? code ?? '',
          reasonDetail: cancellation.reason,
          cashMoved: cancellation.cashMoved,
          cancelledByName: cancellation.cancelledByName,
          labels: labels,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Ticket d\'annulation illisible : $e'));
    }
  }
}
