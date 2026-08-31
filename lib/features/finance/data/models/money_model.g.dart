// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoneyModel _$MoneyModelFromJson(Map<String, dynamic> json) => MoneyModel(
  amountInCents: (json['amountInCents'] as num).toInt(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$MoneyModelToJson(MoneyModel instance) =>
    <String, dynamic>{
      'amountInCents': instance.amountInCents,
      'currency': instance.currency,
    };
