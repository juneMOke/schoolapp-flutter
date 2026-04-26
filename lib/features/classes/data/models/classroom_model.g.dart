// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassroomModel _$ClassroomModelFromJson(Map<String, dynamic> json) =>
    ClassroomModel(
      id: json['id'] as String,
      schoolLevelGroupId: json['schoolLevelGroupId'] as String,
      schoolLevelId: json['schoolLevelId'] as String,
      academicYearId: json['academicYearId'] as String,
      name: json['name'] as String,
      capacity: (json['capacity'] as num).toInt(),
      teacherId: json['teacherId'] as String?,
      teacherFirstName: json['teacherFirstName'] as String?,
      teacherLastName: json['teacherLastName'] as String?,
      teacherMiddleName: json['teacherMiddleName'] as String?,
      totalCount: (json['totalCount'] as num).toInt(),
      femaleCount: (json['femaleCount'] as num).toInt(),
      maleCount: (json['maleCount'] as num).toInt(),
    );

Map<String, dynamic> _$ClassroomModelToJson(ClassroomModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'schoolLevelGroupId': instance.schoolLevelGroupId,
      'schoolLevelId': instance.schoolLevelId,
      'academicYearId': instance.academicYearId,
      'name': instance.name,
      'capacity': instance.capacity,
      'teacherId': instance.teacherId,
      'teacherFirstName': instance.teacherFirstName,
      'teacherLastName': instance.teacherLastName,
      'teacherMiddleName': instance.teacherMiddleName,
      'totalCount': instance.totalCount,
      'femaleCount': instance.femaleCount,
      'maleCount': instance.maleCount,
    };
