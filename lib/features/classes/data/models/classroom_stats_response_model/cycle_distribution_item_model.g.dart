// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_distribution_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CycleDistributionItemModel _$CycleDistributionItemModelFromJson(
  Map<String, dynamic> json,
) => CycleDistributionItemModel(
  cycleId: json['cycleId'] as String,
  cycleCode: json['cycleCode'] as String,
  total: (json['total'] as num).toInt(),
  levels: (json['levels'] as List<dynamic>)
      .map(
        (e) => LevelDistributionItemModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$CycleDistributionItemModelToJson(
  CycleDistributionItemModel instance,
) => <String, dynamic>{
  'cycleId': instance.cycleId,
  'cycleCode': instance.cycleCode,
  'total': instance.total,
  'levels': instance.levels,
};
