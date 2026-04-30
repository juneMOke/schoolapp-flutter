import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';

enum AttendanceStatus { initial, loading, success, failure }

enum AttendanceErrorType {
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

class AttendanceState extends Equatable {
  final AttendanceStatus fetchStatus;
  final List<AttendanceRecord> records;
  final AttendanceErrorType fetchErrorType;

  final AttendanceStatus recordStatus;
  final AttendanceErrorType recordErrorType;

  const AttendanceState({
    this.fetchStatus = AttendanceStatus.initial,
    this.records = const [],
    this.fetchErrorType = AttendanceErrorType.none,
    this.recordStatus = AttendanceStatus.initial,
    this.recordErrorType = AttendanceErrorType.none,
  });

  AttendanceState copyWith({
    AttendanceStatus? fetchStatus,
    List<AttendanceRecord>? records,
    AttendanceErrorType? fetchErrorType,
    AttendanceStatus? recordStatus,
    AttendanceErrorType? recordErrorType,
  }) => AttendanceState(
    fetchStatus: fetchStatus ?? this.fetchStatus,
    records: records ?? this.records,
    fetchErrorType: fetchErrorType ?? this.fetchErrorType,
    recordStatus: recordStatus ?? this.recordStatus,
    recordErrorType: recordErrorType ?? this.recordErrorType,
  );

  @override
  List<Object?> get props => [
    fetchStatus,
    records,
    fetchErrorType,
    recordStatus,
    recordErrorType,
  ];
}
