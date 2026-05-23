// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distribution_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DistributionRequestModel _$DistributionRequestModelFromJson(
  Map<String, dynamic> json,
) => DistributionRequestModel(
  academicYearId: json['academicYearId'] as String,
  schoolLevelGroupId: json['schoolLevelGroupId'] as String,
  schoolLevelId: json['schoolLevelId'] as String,
  distributionCriterion: json['distributionCriterion'] as String,
);

Map<String, dynamic> _$DistributionRequestModelToJson(
  DistributionRequestModel instance,
) => <String, dynamic>{
  'academicYearId': instance.academicYearId,
  'schoolLevelGroupId': instance.schoolLevelGroupId,
  'schoolLevelId': instance.schoolLevelId,
  'distributionCriterion': instance.distributionCriterion,
};
