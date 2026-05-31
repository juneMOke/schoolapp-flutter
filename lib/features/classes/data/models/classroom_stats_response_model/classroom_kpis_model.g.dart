// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_kpis_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassroomKpisModel _$ClassroomKpisModelFromJson(Map<String, dynamic> json) =>
    ClassroomKpisModel(
      totalActive: (json['totalActive'] as num).toInt(),
      activeGirls: (json['activeGirls'] as num).toInt(),
      activeBoys: (json['activeBoys'] as num).toInt(),
      inactive: (json['inactive'] as num).toInt(),
    );

Map<String, dynamic> _$ClassroomKpisModelToJson(ClassroomKpisModel instance) =>
    <String, dynamic>{
      'totalActive': instance.totalActive,
      'activeGirls': instance.activeGirls,
      'activeBoys': instance.activeBoys,
      'inactive': instance.inactive,
    };
