// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_tariff_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeeTariffModel _$FeeTariffModelFromJson(Map<String, dynamic> json) =>
    FeeTariffModel(
      id: json['id'] as String,
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      levelId: json['levelId'] as String,
    );

Map<String, dynamic> _$FeeTariffModelToJson(FeeTariffModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'amount': instance.amount,
      'currency': instance.currency,
      'levelId': instance.levelId,
    };
