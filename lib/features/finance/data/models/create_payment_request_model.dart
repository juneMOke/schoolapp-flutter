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
  final int amountInCents;
  final String currency;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final List<CreatePaymentAllocationRequestModel> allocations;

  const CreatePaymentRequestModel({
    required this.studentId,
    required this.academicYearId,
    required this.amountInCents,
    required this.currency,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    required this.allocations,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'studentId': studentId,
    'academicYearId': academicYearId,
    'amountInCents': amountInCents,
    'currency': currency,
    'payerFirstName': payerFirstName,
    'payerLastName': payerLastName,
    'payerMiddleName': payerMiddleName,
    'allocations': allocations.map((allocation) => allocation.toJson()).toList(),
  };
}
