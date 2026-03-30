part of 'enrollment_bloc.dart';

const _undefined = Object();

enum EnrollmentLoadStatus { initial, loading, success, failure }

enum EnrollmentSummaryQueryType {
  byStatus,
  byStudentName,
  byStudentNamesAndDateOfBirth,
  byDateOfBirth,
}

class EnrollmentState extends Equatable {
  final EnrollmentLoadStatus summariesStatus;
  final EnrollmentLoadStatus detailStatus;
  final List<EnrollmentSummary> summaries;
  final EnrollmentSummaryQueryType? summariesQueryType;
  final EnrollmentDetail? detail;
  final String? errorMessage;

  const EnrollmentState({
    required this.summariesStatus,
    required this.detailStatus,
    required this.summaries,
    required this.summariesQueryType,
    required this.detail,
    required this.errorMessage,
  });

  const EnrollmentState.initial()
    : summariesStatus = EnrollmentLoadStatus.initial,
      detailStatus = EnrollmentLoadStatus.initial,
      summaries = const <EnrollmentSummary>[],
      summariesQueryType = null,
      detail = null,
      errorMessage = null;

  EnrollmentState copyWith({
    EnrollmentLoadStatus? summariesStatus,
    EnrollmentLoadStatus? detailStatus,
    List<EnrollmentSummary>? summaries,
    Object? summariesQueryType = _undefined,
    Object? detail = _undefined,
    Object? errorMessage = _undefined,
  }) {
    return EnrollmentState(
      summariesStatus: summariesStatus ?? this.summariesStatus,
      detailStatus: detailStatus ?? this.detailStatus,
      summaries: summaries ?? this.summaries,
      summariesQueryType: identical(summariesQueryType, _undefined)
          ? this.summariesQueryType
          : summariesQueryType as EnrollmentSummaryQueryType?,
      detail: identical(detail, _undefined)
          ? this.detail
          : detail as EnrollmentDetail?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    summariesStatus,
    detailStatus,
    summaries,
    summariesQueryType,
    detail,
    errorMessage,
  ];
}
