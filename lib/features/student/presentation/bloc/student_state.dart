part of 'student_bloc.dart';

const _undefinedStudent = Object();
const _undefinedAcademicInfo = Object();

enum StudentUpdateStatus { initial, loading, success, failure }

enum StudentUpdateOperation { none, personalInfo, address, academicInfo }

class StudentState extends Equatable {
  final StudentUpdateStatus status;
  final StudentUpdateOperation operation;
  final StudentDetail? updatedStudent;
  final StudentAcademicInfo? updatedAcademicInfo;
  final String? errorMessage;

  const StudentState({
    required this.status,
    required this.operation,
    required this.updatedStudent,
    required this.updatedAcademicInfo,
    required this.errorMessage,
  });

  const StudentState.initial()
      : status = StudentUpdateStatus.initial,
        operation = StudentUpdateOperation.none,
        updatedStudent = null,
        updatedAcademicInfo = null,
        errorMessage = null;

  StudentState copyWith({
    StudentUpdateStatus? status,
    StudentUpdateOperation? operation,
    Object? updatedStudent = _undefinedStudent,
    Object? updatedAcademicInfo = _undefinedAcademicInfo,
    Object? errorMessage = _undefinedStudent,
  }) {
    return StudentState(
      status: status ?? this.status,
      operation: operation ?? this.operation,
      updatedStudent: identical(updatedStudent, _undefinedStudent)
          ? this.updatedStudent
          : updatedStudent as StudentDetail?,
      updatedAcademicInfo: identical(updatedAcademicInfo, _undefinedAcademicInfo)
          ? this.updatedAcademicInfo
          : updatedAcademicInfo as StudentAcademicInfo?,
      errorMessage: identical(errorMessage, _undefinedStudent)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    operation,
    updatedStudent,
    updatedAcademicInfo,
    errorMessage,
  ];
}