// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassroomItemModel _$ClassroomItemModelFromJson(Map<String, dynamic> json) =>
    ClassroomItemModel(
      classroomId: json['classroomId'] as String,
      name: json['name'] as String,
      totalStudents: (json['totalStudents'] as num).toInt(),
      girls: (json['girls'] as num).toInt(),
      boys: (json['boys'] as num).toInt(),
    );

Map<String, dynamic> _$ClassroomItemModelToJson(ClassroomItemModel instance) =>
    <String, dynamic>{
      'classroomId': instance.classroomId,
      'name': instance.name,
      'totalStudents': instance.totalStudents,
      'girls': instance.girls,
      'boys': instance.boys,
    };
