// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentModel _$PaymentModelFromJson(Map<String, dynamic> json) => PaymentModel(
  id: json['id'] as String,
  studentId: json['studentId'] as String,
  academicYearId: json['academicYearId'] as String,
  amountInCents: (json['amountInCents'] as num).toInt(),
  currency: json['currency'] as String,
  payerFirstName: json['payerFirstName'] as String,
  payerLastName: json['payerLastName'] as String,
  payerMiddleName: json['payerMiddleName'] as String?,
  paidAt: DateTime.parse(json['paidAt'] as String),
);

Map<String, dynamic> _$PaymentModelToJson(PaymentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'academicYearId': instance.academicYearId,
      'amountInCents': instance.amountInCents,
      'currency': instance.currency,
      'payerFirstName': instance.payerFirstName,
      'payerLastName': instance.payerLastName,
      'payerMiddleName': instance.payerMiddleName,
      'paidAt': instance.paidAt.toIso8601String(),
    };
