part of 'enrollment_bloc.dart';

const _undefined = Object();

enum EnrollmentLoadStatus { initial, loading, success, failure }

enum EnrollmentSummaryQueryType {
  byStatus,
  byStudentName,
  byStudentNamesAndDateOfBirth,
  byDateOfBirth,
}

class EnrollmentSummariesQuery extends Equatable {
  final EnrollmentSummaryQueryType type;
  final String status;
  final String academicYearId;
  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? dateOfBirth;

  const EnrollmentSummariesQuery({
    required this.type,
    required this.status,
    required this.academicYearId,
    this.firstName,
    this.lastName,
    this.surname,
    this.dateOfBirth,
  });

  @override
  List<Object?> get props => [
    type,
    status,
    academicYearId,
    firstName,
    lastName,
    surname,
    dateOfBirth,
  ];
}

class EnrollmentState extends Equatable {
  final EnrollmentLoadStatus summariesStatus;
  final EnrollmentLoadStatus detailStatus;
  final List<EnrollmentSummary> summaries;
  final EnrollmentSummaryQueryType? summariesQueryType;
  final EnrollmentSummariesQuery? lastSummariesQuery;
  final EnrollmentDetail? detail;
  final String? errorMessage;

  const EnrollmentState({
    required this.summariesStatus,
    required this.detailStatus,
    required this.summaries,
    required this.summariesQueryType,
    required this.lastSummariesQuery,
    required this.detail,
    required this.errorMessage,
  });

  const EnrollmentState.initial()
    : summariesStatus = EnrollmentLoadStatus.initial,
      detailStatus = EnrollmentLoadStatus.initial,
      summaries = const <EnrollmentSummary>[],
      summariesQueryType = null,
      lastSummariesQuery = null,
      detail = null,
      errorMessage = null;

  EnrollmentState copyWith({
    EnrollmentLoadStatus? summariesStatus,
    EnrollmentLoadStatus? detailStatus,
    List<EnrollmentSummary>? summaries,
    Object? summariesQueryType = _undefined,
    Object? lastSummariesQuery = _undefined,
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
      lastSummariesQuery: identical(lastSummariesQuery, _undefined)
          ? this.lastSummariesQuery
          : lastSummariesQuery as EnrollmentSummariesQuery?,
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
    lastSummariesQuery,
    detail,
    errorMessage,
  ];
}
