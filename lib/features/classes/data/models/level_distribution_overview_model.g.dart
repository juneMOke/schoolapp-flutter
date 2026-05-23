// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_distribution_overview_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LevelDistributionOverviewModel _$LevelDistributionOverviewModelFromJson(
  Map<String, dynamic> json,
) => LevelDistributionOverviewModel(
  unassignedEnrollments: (json['unassignedEnrollments'] as List<dynamic>)
      .map((e) => EnrollmentSummaryModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  classrooms: (json['classrooms'] as List<dynamic>)
      .map((e) => ClassroomWithMembersModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LevelDistributionOverviewModelToJson(
  LevelDistributionOverviewModel instance,
) => <String, dynamic>{
  'unassignedEnrollments': instance.unassignedEnrollments,
  'classrooms': instance.classrooms,
};
