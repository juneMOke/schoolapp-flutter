import 'package:school_app_flutter/features/finance/data/models/money_model.dart';

class CreatePaymentAllocationRequestModel {
  final String studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const CreatePaymentAllocationRequestModel({
    required this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'studentChargeId': studentChargeId,
    'feeCode': feeCode,
    'studentChargeLabel': studentChargeLabel,
    'amountInCents': amountInCents,
    'currency': currency,
  };
}

class CreatePaymentRequestModel {
  final String studentId;
  final String academicYearId;

  /// Ce qui est encaissé, **une entrée par devise**. Le serveur le vérifie
  /// contre les imputations DEVISE PAR DEVISE : un total juste globalement mais
  /// mal réparti est refusé (`ALLOCATION_SUM_MISMATCH`).
  final List<MoneyModel> amounts;

  /// Les trois noms sont FACULTATIFS depuis la V114 serveur : `null` quand
  /// l'argent a été pris sans nommer qui le donnait. Ses colonnes l'étaient
  /// depuis la V10 — c'était l'arête HTTP, et elle seule, qui les exigeait.
  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;
  final String? payerPhoneNumber;
  final List<CreatePaymentAllocationRequestModel> allocations;

  const CreatePaymentRequestModel({
    required this.studentId,
    required this.academicYearId,
    required this.amounts,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    required this.allocations,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'studentId': studentId,
    'academicYearId': academicYearId,
    'amounts': [for (final amount in amounts) amount.toJson()],
    'payerFirstName': payerFirstName,
    'payerLastName': payerLastName,
    'payerMiddleName': payerMiddleName,
    'payerPhoneNumber': payerPhoneNumber,
    'allocations': allocations
        .map((allocation) => allocation.toJson())
        .toList(),
  };
}
