import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';

/// Mappe une intention d'encaissement online ([PaymentsCreateRequested]) vers
/// le draft offline-first ([RecordPaymentDraft]) consommé par
/// `FinanceOfflineBloc` (écriture locale + mise en file outbox).
///
/// - `paidAt` : horodatage terrain (UTC ISO-8601) posé au moment de la mise en
///   file locale ;
/// - `method` : laissé nul → le repository applique le défaut CASH ;
/// - `amountInCents` : montant total repris tel quel (money-grade, en cents) ;
/// - chaque [CreatePaymentAllocationInput] devient une [AllocationDraft]
///   (le `studentChargeId` réel est conservé).
RecordPaymentDraft recordPaymentDraftFromRequest(
  PaymentsCreateRequested request,
) {
  return RecordPaymentDraft(
    studentId: request.studentId,
    academicYearId: request.academicYearId,
    currency: request.currency,
    paidAt: DateTime.now().toUtc().toIso8601String(),
    payerFirstName: request.payerFirstName,
    payerLastName: request.payerLastName,
    payerMiddleName: request.payerMiddleName,
    amountInCents: request.amountInCents,
    allocations: [
      for (final allocation in request.allocations)
        AllocationDraft(
          studentChargeId: allocation.studentChargeId,
          feeCode: allocation.feeCode,
          studentChargeLabel: allocation.studentChargeLabel,
          amountInCents: allocation.amountInCents,
          currency: allocation.currency,
        ),
    ],
  );
}
