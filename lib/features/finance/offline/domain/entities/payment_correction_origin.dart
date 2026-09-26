import 'package:equatable/equatable.dart';

/// Une imputation du versement à corriger.
class PaymentCorrectionOriginAllocation extends Equatable {
  final String? studentChargeId;
  final String feeCode;
  final int amountInCents;
  final String currency;

  const PaymentCorrectionOriginAllocation({
    this.studentChargeId,
    required this.feeCode,
    required this.amountInCents,
    required this.currency,
  });

  @override
  List<Object?> get props => [
    studentChargeId,
    feeCode,
    amountInCents,
    currency,
  ];
}

/// Le versement à corriger, tel qu'il faut le remettre sous les yeux du
/// caissier : ce qu'il imputait, dans quelle devise le tiroir l'a reçu, et
/// qui l'a payé. De quoi pré-remplir le formulaire du remplaçant.
class PaymentCorrectionOrigin extends Equatable {
  final String paymentId;
  final String studentId;
  final String? academicYearId;

  /// ISO-8601, la date d'origine (D2 : le remplaçant la reprend).
  final String paidAt;

  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;
  final String? payerPhoneNumber;

  final List<PaymentCorrectionOriginAllocation> allocations;

  /// Pour chaque devise de créance, la devise que le tiroir a reçue quand
  /// elle en diffère (D7 : le moyen de paiement de l'origine est repris).
  final Map<String, String> tenderCurrencyByChargeCurrency;

  const PaymentCorrectionOrigin({
    required this.paymentId,
    required this.studentId,
    this.academicYearId,
    required this.paidAt,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.allocations = const [],
    this.tenderCurrencyByChargeCurrency = const {},
  });

  /// Ce que l'origine imputait, par créance.
  Map<String, int> get centsByCharge => {
    for (final a in allocations)
      if (a.studentChargeId != null) a.studentChargeId!: a.amountInCents,
  };

  @override
  List<Object?> get props => [
    paymentId,
    studentId,
    academicYearId,
    paidAt,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    payerPhoneNumber,
    allocations,
    tenderCurrencyByChargeCurrency,
  ];
}
