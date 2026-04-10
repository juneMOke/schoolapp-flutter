part of 'enrollment_academic_info_bloc.dart';

const _undefinedDetail = Object();

enum EnrollmentAcademicInfoStatus { initial, loading, success, failure }

class EnrollmentAcademicInfoState extends Equatable {
  final EnrollmentAcademicInfoStatus status;
  final EnrollmentAcademicInfoResponse? updatedDetail;
  final String? errorMessage;

  const EnrollmentAcademicInfoState({
    required this.status,
    required this.updatedDetail,
    required this.errorMessage,
  });

  const EnrollmentAcademicInfoState.initial()
      : status = EnrollmentAcademicInfoStatus.initial,
        updatedDetail = null,
        errorMessage = null;

  EnrollmentAcademicInfoState copyWith({
    EnrollmentAcademicInfoStatus? status,
    Object? updatedDetail = _undefinedDetail,
    Object? errorMessage = _undefinedDetail,
  }) {
    return EnrollmentAcademicInfoState(
      status: status ?? this.status,
      updatedDetail: identical(updatedDetail, _undefinedDetail)
          ? this.updatedDetail
          : updatedDetail as EnrollmentAcademicInfoResponse?,
      errorMessage: identical(errorMessage, _undefinedDetail)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, updatedDetail, errorMessage];
}
