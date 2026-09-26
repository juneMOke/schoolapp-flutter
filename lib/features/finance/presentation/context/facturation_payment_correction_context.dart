import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_origin.dart';

/// Ce qu'emporte la page d'encaissement quand elle sert à CORRIGER un
/// versement : l'origine à annuler, de quoi la montrer barrée, et de quoi
/// pré-remplir son remplaçant.
class FacturationPaymentCorrectionContext extends Equatable {
  final PaymentCorrectionOrigin origin;

  /// Ce que l'origine a encaissé, par devise — rappelé barré en tête.
  final MoneyBag originAmounts;

  /// La date d'origine : le remplaçant la reprend par défaut (D2).
  final DateTime originPaidAt;

  const FacturationPaymentCorrectionContext({
    required this.origin,
    required this.originAmounts,
    required this.originPaidAt,
  });

  @override
  List<Object?> get props => [origin, originAmounts, originPaidAt];
}

/// Les créances telles qu'elles seraient **sans** le versement corrigé : ses
/// tranches rouvertes, bornes de saisie comprises.
///
/// Sans cela, les tranches que l'origine a soldées n'apparaîtraient plus comme
/// payables, et réimputer 48 + 2 $ sur ces mêmes tranches serait impossible.
List<StudentCharge> chargesWithoutPayment(
  List<StudentCharge> charges,
  Map<String, int> originCentsByCharge,
) => [
  for (final charge in charges)
    if (originCentsByCharge[charge.id] case final cents?)
      _reopened(charge, cents)
    else
      charge,
];

StudentCharge _reopened(StudentCharge charge, int cents) {
  final pending = charge.amountPaidPendingInCents - cents;
  final paid = charge.amountPaidInCents + pending;
  final status = paid >= charge.expectedAmountInCents
      ? StudentChargeStatus.paid
      : paid > 0
      ? StudentChargeStatus.partial
      : StudentChargeStatus.due;
  return charge.copyWith(amountPaidPendingInCents: pending, status: status);
}
