import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';

/// Mappe une intention d'encaissement online ([PaymentsCreateRequested]) vers
/// le draft offline-first ([RecordPaymentDraft]) consommé par
/// `FinanceOfflineBloc` (écriture locale + mise en file outbox).
///
/// - `paidAt` : le **jour** désigné au guichet, recomposé avec l'heure courante
///   dans le fuseau de l'école, puis rendu en UTC ISO-8601 (cf. ci-dessous) ;
/// - `method` : laissé nul → le repository applique le défaut CASH ;
/// - `amounts` : ce qui est IMPUTÉ, une entrée par devise de créance, repris tel
///   quel (money-grade, en cents) ;
/// - `tenders` : ce qui est PERÇU, une entrée par couple (devise reçue, pivot).
///   Vide ⇒ le repository écrit l'identité, c'est-à-dire le cas courant ;
/// - chaque [CreatePaymentAllocationInput] devient une [AllocationDraft]
///   (le `studentChargeId` réel et le `feeTariffId` de la ligne de grille sont
///   conservés).
///
/// ## Pourquoi la date se recompose ici, et pas à la saisie
///
/// L'écran ne désigne qu'un jour ; l'heure reste celle du geste. Les deux ne
/// sont réunis qu'au dernier moment, et **dans le fuseau de l'école** : la
/// caisse serveur découpe ses journées en heure de Kinshasa, et un poste laissé
/// en UTC ferait basculer un versement de fin de soirée sur le lendemain.
///
/// [now] n'existe que pour les tests : en production, l'horloge est celle du
/// poste, comme pour tout le reste du chemin d'écriture.
RecordPaymentDraft recordPaymentDraftFromRequest(
  PaymentsCreateRequested request, {
  DateTime? now,
}) {
  return RecordPaymentDraft(
    studentId: request.studentId,
    academicYearId: request.academicYearId,
    paidAt: SchoolTime.composeInstant(
      day: request.paidAt,
      now: now ?? DateTime.now(),
    ).toIso8601String(),
    payerFirstName: request.payerFirstName,
    payerLastName: request.payerLastName,
    payerMiddleName: request.payerMiddleName,
    payerPhoneNumber: request.payerPhoneNumber,
    amounts: request.amounts,
    tenders: request.tenders.isEmpty ? null : request.tenders,
    allocations: [
      for (final allocation in request.allocations)
        AllocationDraft(
          studentChargeId: allocation.studentChargeId,
          feeTariffId: allocation.feeTariffId,
          feeCode: allocation.feeCode,
          studentChargeLabel: allocation.studentChargeLabel,
          amountInCents: allocation.amountInCents,
          currency: allocation.currency,
        ),
    ],
  );
}
