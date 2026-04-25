// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_allocations_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentAllocationsModel _$PaymentAllocationsModelFromJson(
  Map<String, dynamic> json,
) => PaymentAllocationsModel(
  id: json['id'] as String,
  paymentId: json['paymentId'] as String,
  studentChargeId: json['studentChargeId'] as String,
  feeCode: json['feeCode'] as String,
  studentChargeLabel: json['studentChargeLabel'] as String,
  amountInCents: (json['amountInCents'] as num).toInt(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$PaymentAllocationsModelToJson(
  PaymentAllocationsModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'paymentId': instance.paymentId,
  'studentChargeId': instance.studentChargeId,
  'feeCode': instance.feeCode,
  'studentChargeLabel': instance.studentChargeLabel,
  'amountInCents': instance.amountInCents,
  'currency': instance.currency,
};
