import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

enum ClassroomStatsStatus { initial, loading, success, error }

enum ClassroomStatsErrorType {
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

const _undefined = Object();

class ClassroomStatsState extends Equatable {
  final ClassroomStatsStatus status;
  final ClassroomStats? stats;
  final ClassroomStatsErrorType errorType;
  final String? errorMessage;

  const ClassroomStatsState({
    this.status = ClassroomStatsStatus.initial,
    this.stats,
    this.errorType = ClassroomStatsErrorType.none,
    this.errorMessage,
  });

  ClassroomStatsState copyWith({
    ClassroomStatsStatus? status,
    Object? stats = _undefined,
    ClassroomStatsErrorType? errorType,
    Object? errorMessage = _undefined,
  }) => ClassroomStatsState(
    status: status ?? this.status,
    stats: identical(stats, _undefined) ? this.stats : stats as ClassroomStats?,
    errorType: errorType ?? this.errorType,
    errorMessage: identical(errorMessage, _undefined)
        ? this.errorMessage
        : errorMessage as String?,
  );

  @override
  List<Object?> get props => [status, stats, errorType, errorMessage];
}
