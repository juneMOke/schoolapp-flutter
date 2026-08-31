import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Ponts des entités LOCALES (grand-livre offline, argent en `int` centimes,
/// reste composé au read) vers les entités ONLINE consommées par les BLoCs et
/// l'UII de Facturation (Stratégie C : présentation online inchangée, données
/// alimentées par le local). Le solde optimiste/pending traverse via les champs
/// composés ajoutés aux entités online (`amountPaidPendingInCents`, `isProvisional`).
extension LocalStudentChargeToOnline on LocalStudentCharge {
  StudentCharge toOnlineEntity() => StudentCharge(
    id: id,
    studentId: studentId,
    academicYearId: academicYearId ?? '',
    schoolLevelId: schoolLevelId ?? '',
    schoolLevelGroupId: schoolLevelGroupId ?? '',
    feeTariffId: feeTariffId ?? '',
    feeCode: feeCode,
    label: label,
    expectedAmountInCents: expectedAmountInCents.toDouble(),
    amountPaidInCents: amountPaidInCents.toDouble(), // miroir serveur
    amountPaidPendingInCents: amountPaidPendingInCents.toDouble(), // composé
    isProvisional: isProvisional,
    currency: currency,
    status: status,
    dueAt: dueAt,
  );
}

extension LocalPaymentToOnline on LocalPayment {
  Payment toOnlineEntity() => Payment(
    id: id,
    studentId: studentId,
    academicYearId: academicYearId ?? '',
    amounts: amounts,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    payerPhoneNumber: payerPhoneNumber,
    // `paidAt` local = ISO-8601 (heure métier). Parse tolérant : une date
    // malformée est un bug de données, on retombe sur l'epoch (jamais un crash).
    paidAt: DateTime.tryParse(paidAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
    // PENDING_SYNC (ou SYNC_ERROR) = pas encore remonté au serveur (FRONT §3).
    isPendingSync: !syncState.isSynced,
    // Stampés à l'encaissement (v19) et jusqu'ici perdus ici même : le DAO les
    // ramène, ce mapper les laissait tomber, et l'écran de détail affichait un
    // « Encaissé par » vide sur une donnée pourtant présente en base.
    cashierFirstName: cashierFirstName,
    cashierLastName: cashierLastName,
    // Le repli quand rien n'a été stampé ici (versement d'un autre guichet) —
    // c'est `Payment.cashierFullName` qui arbitre entre les deux.
    collectedByName: collectedByName,
  );
}

extension LocalPaymentAllocationToOnline on LocalPaymentAllocation {
  PaymentAllocation toOnlineEntity() => PaymentAllocation(
    id: id,
    paymentId: paymentId,
    // Allocation d'avance (studentChargeId null) → chaîne vide côté online.
    studentChargeId: studentChargeId ?? '',
    feeCode: feeCode,
    studentChargeLabel: studentChargeLabel,
    amountInCents: amountInCents,
    currency: currency,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    payerPhoneNumber: payerPhoneNumber,
    // `paidAt` local = ISO-8601 (heure métier). Parse tolérant : une date
    // malformée ou absente laisse `paidAt` nul (l'UI affiche « inconnu »).
    paidAt: paidAt == null ? null : DateTime.tryParse(paidAt!),
  );
}
