import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';

sealed class ClassroomEvent extends Equatable {
  const ClassroomEvent();
}

class ClassroomRequested extends ClassroomEvent {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String academicYearId;

  const ClassroomRequested({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelId,
    academicYearId,
  ];
}

class ClassroomResetRequested extends ClassroomEvent {
  const ClassroomResetRequested();

  @override
  List<Object?> get props => [];
}

class ClassroomDistributionRequested extends ClassroomEvent {
  final String academicYearId;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final ClassroomDistributionCriterion distributionCriterion;

  const ClassroomDistributionRequested({
    required this.academicYearId,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.distributionCriterion,
  });

  @override
  List<Object?> get props => [
    academicYearId,
    schoolLevelGroupId,
    schoolLevelId,
    distributionCriterion,
  ];
}

class ClassroomMembersRequested extends ClassroomEvent {
  final String classroomId;
  final String academicYearId;

  const ClassroomMembersRequested({
    required this.classroomId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [classroomId, academicYearId];
}

class ClassroomDistributionOverviewRequested extends ClassroomEvent {
  final String academicYearId;
  final String schoolLevelId;

  const ClassroomDistributionOverviewRequested({
    required this.academicYearId,
    required this.schoolLevelId,
  });

  @override
  List<Object?> get props => [academicYearId, schoolLevelId];
}

class ClassroomMembersBatchRequested extends ClassroomEvent {
  final List<String> classroomIds;
  final String academicYearId;

  const ClassroomMembersBatchRequested({
    required this.classroomIds,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [classroomIds, academicYearId];
}

class ClassroomMemberReassignRequested extends ClassroomEvent {
  final String classroomMemberId;
  final String targetClassroomId;

  const ClassroomMemberReassignRequested({
    required this.classroomMemberId,
    required this.targetClassroomId,
  });

  @override
  List<Object?> get props => [
    classroomMemberId,
    targetClassroomId,
  ];
}
