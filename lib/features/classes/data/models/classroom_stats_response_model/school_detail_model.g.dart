// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolDetailModel _$SchoolDetailModelFromJson(Map<String, dynamic> json) =>
    SchoolDetailModel(
      totalStudents: (json['totalStudents'] as num).toInt(),
      girls: (json['girls'] as num).toInt(),
      boys: (json['boys'] as num).toInt(),
      cycles: (json['cycles'] as List<dynamic>)
          .map((e) => CycleDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SchoolDetailModelToJson(SchoolDetailModel instance) =>
    <String, dynamic>{
      'totalStudents': instance.totalStudents,
      'girls': instance.girls,
      'boys': instance.boys,
      'cycles': instance.cycles,
    };
