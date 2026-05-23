import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';

part 'distribution_request_model.g.dart';

@JsonSerializable()
class DistributionRequestModel {
  final String academicYearId;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String distributionCriterion;

  const DistributionRequestModel({
    required this.academicYearId,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.distributionCriterion,
  });

  factory DistributionRequestModel.fromDomain({
    required String academicYearId,
    required String schoolLevelGroupId,
    required String schoolLevelId,
    required ClassroomDistributionCriterion distributionCriterion,
  }) {
    return DistributionRequestModel(
      academicYearId: academicYearId,
      schoolLevelGroupId: schoolLevelGroupId,
      schoolLevelId: schoolLevelId,
      distributionCriterion: distributionCriterion.toApiValue(),
    );
  }

  factory DistributionRequestModel.fromJson(Map<String, dynamic> json) =>
      _$DistributionRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$DistributionRequestModelToJson(this);
}
