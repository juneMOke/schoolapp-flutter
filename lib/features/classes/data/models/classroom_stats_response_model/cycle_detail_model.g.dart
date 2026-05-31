// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CycleDetailModel _$CycleDetailModelFromJson(Map<String, dynamic> json) =>
    CycleDetailModel(
      cycleId: json['cycleId'] as String,
      cycleCode: json['cycleCode'] as String,
      totalStudents: (json['totalStudents'] as num).toInt(),
      girls: (json['girls'] as num).toInt(),
      boys: (json['boys'] as num).toInt(),
      levels: (json['levels'] as List<dynamic>)
          .map((e) => LevelDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CycleDetailModelToJson(CycleDetailModel instance) =>
    <String, dynamic>{
      'cycleId': instance.cycleId,
      'cycleCode': instance.cycleCode,
      'totalStudents': instance.totalStudents,
      'girls': instance.girls,
      'boys': instance.boys,
      'levels': instance.levels,
    };
