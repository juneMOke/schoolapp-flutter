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
