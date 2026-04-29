import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';

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
  final ClassroomStatus reassignStatus;
  final ClassroomErrorType reassignErrorType;
  final String reassigningMemberId;

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
    this.reassignStatus = ClassroomStatus.initial,
    this.reassignErrorType = ClassroomErrorType.none,
    this.reassigningMemberId = '',
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
    ClassroomStatus? reassignStatus,
    ClassroomErrorType? reassignErrorType,
    String? reassigningMemberId,
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
    reassignStatus: reassignStatus ?? this.reassignStatus,
    reassignErrorType: reassignErrorType ?? this.reassignErrorType,
    reassigningMemberId: reassigningMemberId ?? this.reassigningMemberId,
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
    reassignStatus,
    reassignErrorType,
    reassigningMemberId,
  ];
}
