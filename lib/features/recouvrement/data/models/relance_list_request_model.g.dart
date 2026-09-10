// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relance_list_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$RelanceAmountModelToJson(RelanceAmountModel instance) =>
    <String, dynamic>{
      'currency': instance.currency,
      'amountInCents': instance.amountInCents,
    };

Map<String, dynamic> _$RelanceLineModelToJson(RelanceLineModel instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'due': instance.due.map((e) => e.toJson()).toList(),
      'paid': instance.paid.map((e) => e.toJson()).toList(),
      'outstanding': instance.outstanding.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$RelanceScopeModelToJson(RelanceScopeModel instance) =>
    <String, dynamic>{'kind': instance.kind, 'id': ?instance.id};

Map<String, dynamic> _$RelanceListRequestModelToJson(
  RelanceListRequestModel instance,
) => <String, dynamic>{
  'scope': instance.scope.toJson(),
  'feeCodes': instance.feeCodes,
  'criterion': instance.criterion,
  'thresholdInCents': ?instance.thresholdInCents,
  'thresholdCurrency': ?instance.thresholdCurrency,
  'arretedAt': instance.arretedAt,
  'pendingWrites': ?instance.pendingWrites,
  'lines': instance.lines.map((e) => e.toJson()).toList(),
};
