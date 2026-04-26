import 'package:equatable/equatable.dart';
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
  final ClassroomStatus distributionStatus;
  final ClassroomErrorType distributionErrorType;

  const ClassroomState({
    this.status = ClassroomStatus.initial,
    this.classrooms = const [],
    this.errorType = ClassroomErrorType.none,
    this.distributionStatus = ClassroomStatus.initial,
    this.distributionErrorType = ClassroomErrorType.none,
  });

  ClassroomState copyWith({
    ClassroomStatus? status,
    List<Classroom>? classrooms,
    ClassroomErrorType? errorType,
    ClassroomStatus? distributionStatus,
    ClassroomErrorType? distributionErrorType,
  }) => ClassroomState(
    status: status ?? this.status,
    classrooms: classrooms ?? this.classrooms,
    errorType: errorType ?? this.errorType,
    distributionStatus: distributionStatus ?? this.distributionStatus,
    distributionErrorType: distributionErrorType ?? this.distributionErrorType,
  );

  @override
  List<Object?> get props => [
    status,
    classrooms,
    errorType,
    distributionStatus,
    distributionErrorType,
  ];
}
