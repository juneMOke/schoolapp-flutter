// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_stats_context_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassroomStatsContextModel _$ClassroomStatsContextModelFromJson(
  Map<String, dynamic> json,
) => ClassroomStatsContextModel(
  academicYearId: json['academicYearId'] as String,
  academicYearName: json['academicYearName'] as String,
  generatedAt: DateTime.parse(json['generatedAt'] as String),
);

Map<String, dynamic> _$ClassroomStatsContextModelToJson(
  ClassroomStatsContextModel instance,
) => <String, dynamic>{
  'academicYearId': instance.academicYearId,
  'academicYearName': instance.academicYearName,
  'generatedAt': instance.generatedAt.toIso8601String(),
};
