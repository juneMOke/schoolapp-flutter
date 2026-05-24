// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_stats_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassroomStatsResponseModel _$ClassroomStatsResponseModelFromJson(
  Map<String, dynamic> json,
) => ClassroomStatsResponseModel(
  context: ClassroomStatsContextModel.fromJson(
    json['context'] as Map<String, dynamic>,
  ),
  kpis: ClassroomKpisModel.fromJson(json['kpis'] as Map<String, dynamic>),
  distributionByCycle: (json['distributionByCycle'] as List<dynamic>)
      .map(
        (e) => CycleDistributionItemModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  detail: ClassroomDetailModel.fromJson(json['detail'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ClassroomStatsResponseModelToJson(
  ClassroomStatsResponseModel instance,
) => <String, dynamic>{
  'context': instance.context,
  'kpis': instance.kpis,
  'distributionByCycle': instance.distributionByCycle,
  'detail': instance.detail,
};
