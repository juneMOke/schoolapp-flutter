// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LevelDetailModel _$LevelDetailModelFromJson(Map<String, dynamic> json) =>
    LevelDetailModel(
      levelId: json['levelId'] as String,
      levelCode: json['levelCode'] as String,
      totalStudents: (json['totalStudents'] as num).toInt(),
      girls: (json['girls'] as num).toInt(),
      boys: (json['boys'] as num).toInt(),
      classrooms: (json['classrooms'] as List<dynamic>)
          .map((e) => ClassroomItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LevelDetailModelToJson(LevelDetailModel instance) =>
    <String, dynamic>{
      'levelId': instance.levelId,
      'levelCode': instance.levelCode,
      'totalStudents': instance.totalStudents,
      'girls': instance.girls,
      'boys': instance.boys,
      'classrooms': instance.classrooms,
    };
