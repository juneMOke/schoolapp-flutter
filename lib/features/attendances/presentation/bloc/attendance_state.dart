import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';

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
  final List<AttendanceEditableRow> draftRows;
  final AttendanceErrorType fetchErrorType;

  final AttendanceStatus saveStatus;
  final AttendanceErrorType saveErrorType;
  final String? activeClassroomId;
  final String? activeAcademicYearId;
  final DateTime? activeDate;
  final bool hasUnsavedChanges;
  final bool hasValidationErrors;
  final Set<String> modifiedStudentIds;

  const AttendanceState({
    this.fetchStatus = AttendanceStatus.initial,
    this.records = const [],
    this.draftRows = const [],
    this.fetchErrorType = AttendanceErrorType.none,
    this.saveStatus = AttendanceStatus.initial,
    this.saveErrorType = AttendanceErrorType.none,
    this.activeClassroomId,
    this.activeAcademicYearId,
    this.activeDate,
    this.hasUnsavedChanges = false,
    this.hasValidationErrors = false,
    this.modifiedStudentIds = const <String>{},
  });

  AttendanceState copyWith({
    AttendanceStatus? fetchStatus,
    List<AttendanceRecord>? records,
    List<AttendanceEditableRow>? draftRows,
    AttendanceErrorType? fetchErrorType,
    AttendanceStatus? saveStatus,
    AttendanceErrorType? saveErrorType,
    Object? activeClassroomId = _undefined,
    Object? activeAcademicYearId = _undefined,
    Object? activeDate = _undefined,
    bool? hasUnsavedChanges,
    bool? hasValidationErrors,
    Set<String>? modifiedStudentIds,
  }) => AttendanceState(
    fetchStatus: fetchStatus ?? this.fetchStatus,
    records: records ?? this.records,
    draftRows: draftRows ?? this.draftRows,
    fetchErrorType: fetchErrorType ?? this.fetchErrorType,
    saveStatus: saveStatus ?? this.saveStatus,
    saveErrorType: saveErrorType ?? this.saveErrorType,
    activeClassroomId: identical(activeClassroomId, _undefined)
        ? this.activeClassroomId
        : activeClassroomId as String?,
    activeAcademicYearId: identical(activeAcademicYearId, _undefined)
        ? this.activeAcademicYearId
        : activeAcademicYearId as String?,
    activeDate: identical(activeDate, _undefined)
        ? this.activeDate
        : activeDate as DateTime?,
    hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    hasValidationErrors: hasValidationErrors ?? this.hasValidationErrors,
    modifiedStudentIds: modifiedStudentIds ?? this.modifiedStudentIds,
  );

  bool get canSave =>
      draftRows.isNotEmpty &&
      hasUnsavedChanges &&
      !hasValidationErrors &&
      saveStatus != AttendanceStatus.loading;

  int get modifiedCount => modifiedStudentIds.length;

  @override
  List<Object?> get props => [
    fetchStatus,
    records,
    draftRows,
    fetchErrorType,
    saveStatus,
    saveErrorType,
    activeClassroomId,
    activeAcademicYearId,
    activeDate,
    hasUnsavedChanges,
    hasValidationErrors,
    modifiedStudentIds,
  ];
}

const _undefined = Object();
