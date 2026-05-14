import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_with_members_model.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_summary_model.dart';

part 'level_distribution_overview_model.g.dart';

@JsonSerializable()
class LevelDistributionOverviewModel extends Equatable {
  final List<EnrollmentSummaryModel> unassignedEnrollments;
  final List<ClassroomWithMembersModel> classrooms;

  const LevelDistributionOverviewModel({
    required this.unassignedEnrollments,
    required this.classrooms,
  });

  factory LevelDistributionOverviewModel.fromJson(Map<String, dynamic> json) =>
      _$LevelDistributionOverviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$LevelDistributionOverviewModelToJson(this);

  LevelDistributionOverview toEntity() => LevelDistributionOverview(
        unassignedEnrollments: unassignedEnrollments
            .map((enrollment) => enrollment.toEnrollmentSummary())
            .toList(growable: false),
        classrooms: classrooms.map((classroom) => classroom.toEntity()).toList(growable: false),
      );

  @override
  List<Object?> get props => [unassignedEnrollments, classrooms];
}
