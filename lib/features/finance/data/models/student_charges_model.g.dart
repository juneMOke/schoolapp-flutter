// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_charges_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentChargesModel _$StudentChargesModelFromJson(Map<String, dynamic> json) =>
    StudentChargesModel(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      academicYearId: json['academicYearId'] as String,
      schoolLevelId: json['schoolLevelId'] as String,
      schoolLevelGroupId: json['schoolLevelGroupId'] as String,
      feeTariffId: json['feeTariffId'] as String,
      feeCode: json['feeCode'] as String,
      label: json['label'] as String,
      expectedAmountInCents: (json['expectedAmountInCents'] as num).toDouble(),
      amountPaidInCents: (json['amountPaidInCents'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$StudentChargesModelToJson(
  StudentChargesModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'studentId': instance.studentId,
  'academicYearId': instance.academicYearId,
  'schoolLevelId': instance.schoolLevelId,
  'schoolLevelGroupId': instance.schoolLevelGroupId,
  'feeTariffId': instance.feeTariffId,
  'feeCode': instance.feeCode,
  'label': instance.label,
  'expectedAmountInCents': instance.expectedAmountInCents,
  'amountPaidInCents': instance.amountPaidInCents,
  'currency': instance.currency,
  'status': instance.status,
};
