import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';

enum ClassroomStatus { initial, loading, success, failure }

enum ClassroomErrorType {
  none,
  network,
  notFound,
  validation,
  unauthorized,
  invalidCredentials,
  server,
  storage,
  auth,
  unknown,
}

class ClassroomMembersGroup extends Equatable {
  final String classroomId;
  final List<ClassroomMember> members;

  const ClassroomMembersGroup({
    required this.classroomId,
    required this.members,
  });

  @override
  List<Object?> get props => [classroomId, members];
}

class ClassroomState extends Equatable {
  final ClassroomStatus status;
  final List<Classroom> classrooms;
  final ClassroomErrorType errorType;
  final ClassroomStatus membersStatus;
  final List<ClassroomMember> members;
  final List<ClassroomMembersGroup> membersByClassroom;
  final int membersLoadingCount;
  final ClassroomErrorType membersErrorType;
  final ClassroomStatus distributionStatus;
  final ClassroomErrorType distributionErrorType;
  final bool distributionRePullFailed;
  final ClassroomStatus distributionOverviewStatus;
  final ClassroomErrorType distributionOverviewErrorType;
  final LevelDistributionOverview? distributionOverview;

  const ClassroomState({
    this.status = ClassroomStatus.initial,
    this.classrooms = const [],
    this.errorType = ClassroomErrorType.none,
    this.membersStatus = ClassroomStatus.initial,
    this.members = const [],
    this.membersByClassroom = const [],
    this.membersLoadingCount = 0,
    this.membersErrorType = ClassroomErrorType.none,
    this.distributionStatus = ClassroomStatus.initial,
    this.distributionErrorType = ClassroomErrorType.none,
    this.distributionRePullFailed = false,
    this.distributionOverviewStatus = ClassroomStatus.initial,
    this.distributionOverviewErrorType = ClassroomErrorType.none,
    this.distributionOverview,
  });

  ClassroomState copyWith({
    ClassroomStatus? status,
    List<Classroom>? classrooms,
    ClassroomErrorType? errorType,
    ClassroomStatus? membersStatus,
    List<ClassroomMember>? members,
    List<ClassroomMembersGroup>? membersByClassroom,
    int? membersLoadingCount,
    ClassroomErrorType? membersErrorType,
    ClassroomStatus? distributionStatus,
    ClassroomErrorType? distributionErrorType,
    bool? distributionRePullFailed,
    ClassroomStatus? distributionOverviewStatus,
    ClassroomErrorType? distributionOverviewErrorType,
    Object? distributionOverview = _undefined,
  }) => ClassroomState(
    status: status ?? this.status,
    classrooms: classrooms ?? this.classrooms,
    errorType: errorType ?? this.errorType,
    membersStatus: membersStatus ?? this.membersStatus,
    members: members ?? this.members,
    membersByClassroom: membersByClassroom ?? this.membersByClassroom,
    membersLoadingCount: membersLoadingCount ?? this.membersLoadingCount,
    membersErrorType: membersErrorType ?? this.membersErrorType,
    distributionStatus: distributionStatus ?? this.distributionStatus,
    distributionErrorType: distributionErrorType ?? this.distributionErrorType,
    distributionRePullFailed:
        distributionRePullFailed ?? this.distributionRePullFailed,
    distributionOverviewStatus:
        distributionOverviewStatus ?? this.distributionOverviewStatus,
    distributionOverviewErrorType:
        distributionOverviewErrorType ?? this.distributionOverviewErrorType,
    distributionOverview: identical(distributionOverview, _undefined)
        ? this.distributionOverview
        : distributionOverview as LevelDistributionOverview?,
  );

  @override
  List<Object?> get props => [
    status,
    classrooms,
    errorType,
    membersStatus,
    members,
    membersByClassroom,
    membersLoadingCount,
    membersErrorType,
    distributionStatus,
    distributionErrorType,
    distributionRePullFailed,
    distributionOverviewStatus,
    distributionOverviewErrorType,
    distributionOverview,
  ];
}

const _undefined = Object();
