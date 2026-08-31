// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_tariff_payload_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$FeeTariffPayloadModelToJson(
  FeeTariffPayloadModel instance,
) => <String, dynamic>{
  'feeCode': instance.feeCode,
  'label': instance.label,
  'schoolLevelGroupId': instance.schoolLevelGroupId,
  'schoolLevelId': instance.schoolLevelId,
  'academicYearId': instance.academicYearId,
  'amountInCents': instance.amountInCents,
  'currency': instance.currency,
  'dueAt': ?instance.dueAt,
};

FeeTariffResponseModel _$FeeTariffResponseModelFromJson(
  Map<String, dynamic> json,
) => FeeTariffResponseModel(
  id: json['id'] as String? ?? '',
  feeCode: json['feeCode'] as String? ?? '',
  label: json['label'] as String?,
  amountInCents: (json['amountInCents'] as num?)?.toInt() ?? 0,
  currency: json['currency'] as String? ?? 'USD',
  dueAt: json['dueAt'] as String?,
  schoolLevelId: json['schoolLevelId'] as String?,
  schoolLevelGroupId: json['schoolLevelGroupId'] as String?,
);
