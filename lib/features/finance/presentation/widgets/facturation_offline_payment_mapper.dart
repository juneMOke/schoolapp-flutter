import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';

/// Mappe une intention d'encaissement online ([PaymentsCreateRequested]) vers
/// le draft offline-first ([RecordPaymentDraft]) consommé par
/// `FinanceOfflineBloc` (écriture locale + mise en file outbox).
///
/// - `paidAt` : l'**instant de l'écriture**, rendu en UTC ISO-8601 (cf.
///   ci-dessous) ;
/// - `method` : laissé nul → le repository applique le défaut CASH ;
/// - `amounts` : ce qui est IMPUTÉ, une entrée par devise de créance, repris tel
///   quel (money-grade, en cents) ;
/// - `tenders` : ce qui est PERÇU, une entrée par couple (devise reçue, pivot).
///   Vide ⇒ le repository écrit l'identité, c'est-à-dire le cas courant ;
/// - chaque [CreatePaymentAllocationInput] devient une [AllocationDraft]
///   (le `studentChargeId` réel et le `feeTariffId` de la ligne de grille sont
///   conservés).
///
/// ## Pourquoi l'instant de l'écriture, et non le jour de la requête
///
/// Un versement est daté du jour de sa saisie (continuité des tickets RC,
/// lot C) : plus aucun jour ne se désigne. Recomposer le jour de la requête
/// avec l'heure courante datait de la VEILLE un encaissement validé juste après
/// minuit, la requête ayant été construite juste avant — à minuit passé de
/// dix secondes, le versement tombait au début de la journée précédente, en
/// tête de la pile d'hier. L'instant réel ne connaît pas ce piège.
///
/// Une correction n'en dépend pas : `withOriginInstant` réécrit ensuite
/// l'instant du remplaçant sur celui de l'origine.
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
    paidAt: (now ?? DateTime.now()).toUtc().toIso8601String(),
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
