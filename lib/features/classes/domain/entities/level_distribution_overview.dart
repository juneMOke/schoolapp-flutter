import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_with_members.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';

class LevelDistributionOverview extends Equatable {
  final List<EnrollmentSummary> unassignedEnrollments;
  final List<ClassroomWithMembers> classrooms;

  const LevelDistributionOverview({
    required this.unassignedEnrollments,
    required this.classrooms,
  });

  @override
  List<Object?> get props => [unassignedEnrollments, classrooms];
}
