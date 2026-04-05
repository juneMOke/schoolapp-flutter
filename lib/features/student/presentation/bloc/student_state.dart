part of 'student_bloc.dart';

const _undefinedStudent = Object();

enum StudentUpdateStatus { initial, loading, success, failure }

class StudentState extends Equatable {
  final StudentUpdateStatus status;
  final StudentDetail? updatedStudent;
  final String? errorMessage;

  const StudentState({
    required this.status,
    required this.updatedStudent,
    required this.errorMessage,
  });

  const StudentState.initial()
      : status = StudentUpdateStatus.initial,
        updatedStudent = null,
        errorMessage = null;

  StudentState copyWith({
    StudentUpdateStatus? status,
    Object? updatedStudent = _undefinedStudent,
    Object? errorMessage = _undefinedStudent,
  }) {
    return StudentState(
      status: status ?? this.status,
      updatedStudent: identical(updatedStudent, _undefinedStudent)
          ? this.updatedStudent
          : updatedStudent as StudentDetail?,
      errorMessage: identical(errorMessage, _undefinedStudent)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, updatedStudent, errorMessage];
}
