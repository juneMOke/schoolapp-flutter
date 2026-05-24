// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_distribution_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LevelDistributionItemModel _$LevelDistributionItemModelFromJson(
  Map<String, dynamic> json,
) => LevelDistributionItemModel(
  levelId: json['levelId'] as String,
  levelCode: json['levelCode'] as String,
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$LevelDistributionItemModelToJson(
  LevelDistributionItemModel instance,
) => <String, dynamic>{
  'levelId': instance.levelId,
  'levelCode': instance.levelCode,
  'total': instance.total,
};
