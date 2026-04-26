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

class ClassroomState extends Equatable {
  final ClassroomStatus status;
  final List<Classroom> classrooms;
  final ClassroomErrorType errorType;
  final ClassroomStatus membersStatus;
  final List<ClassroomMember> members;
  final ClassroomErrorType membersErrorType;
  final ClassroomStatus distributionStatus;
  final ClassroomErrorType distributionErrorType;

  const ClassroomState({
    this.status = ClassroomStatus.initial,
    this.classrooms = const [],
    this.errorType = ClassroomErrorType.none,
    this.membersStatus = ClassroomStatus.initial,
    this.members = const [],
    this.membersErrorType = ClassroomErrorType.none,
    this.distributionStatus = ClassroomStatus.initial,
    this.distributionErrorType = ClassroomErrorType.none,
  });

  ClassroomState copyWith({
    ClassroomStatus? status,
    List<Classroom>? classrooms,
    ClassroomErrorType? errorType,
    ClassroomStatus? membersStatus,
    List<ClassroomMember>? members,
    ClassroomErrorType? membersErrorType,
    ClassroomStatus? distributionStatus,
    ClassroomErrorType? distributionErrorType,
  }) => ClassroomState(
    status: status ?? this.status,
    classrooms: classrooms ?? this.classrooms,
    errorType: errorType ?? this.errorType,
    membersStatus: membersStatus ?? this.membersStatus,
    members: members ?? this.members,
    membersErrorType: membersErrorType ?? this.membersErrorType,
    distributionStatus: distributionStatus ?? this.distributionStatus,
    distributionErrorType: distributionErrorType ?? this.distributionErrorType,
  );

  @override
  List<Object?> get props => [
    status,
    classrooms,
    errorType,
    membersStatus,
    members,
    membersErrorType,
    distributionStatus,
    distributionErrorType,
  ];
}
