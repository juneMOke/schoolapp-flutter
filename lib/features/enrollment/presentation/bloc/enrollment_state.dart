part of 'enrollment_bloc.dart';

const _undefined = Object();

enum EnrollmentLoadStatus { initial, loading, success, failure }

enum EnrollmentSummaryQueryType {
  byStatus,
  byStudentName,
  byStudentNamesAndDateOfBirth,
  byDateOfBirth,
  byAcademicInfo,
}

class EnrollmentSummariesQuery extends Equatable {
  final EnrollmentSummaryQueryType type;
  final String status;
  final String academicYearId;
  final int page;
  final int size;
  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? dateOfBirth;
  final String? schoolLevelGroupId;
  final String? schoolLevelId;

  const EnrollmentSummariesQuery({
    required this.type,
    required this.status,
    required this.academicYearId,
    required this.page,
    required this.size,
    this.firstName,
    this.lastName,
    this.surname,
    this.dateOfBirth,
    this.schoolLevelGroupId,
    this.schoolLevelId,
  });

  @override
  List<Object?> get props => [
    type,
    status,
    academicYearId,
    page,
    size,
    firstName,
    lastName,
    surname,
    dateOfBirth,
    schoolLevelGroupId,
    schoolLevelId,
  ];
}

class EnrollmentState extends Equatable {
  final EnrollmentLoadStatus createStatus;
  final EnrollmentLoadStatus statusUpdateStatus;
  final EnrollmentLoadStatus summariesStatus;
  final EnrollmentLoadStatus detailStatus;
  final EnrollmentLoadStatus previewStatus;
  final List<EnrollmentSummary> summaries;
  final int summariesPage;
  final int summariesSize;
  final int summariesTotalElements;
  final int summariesTotalPages;
  final EnrollmentSummaryQueryType? summariesQueryType;
  final EnrollmentSummariesQuery? lastSummariesQuery;
  final EnrollmentDetail? detail;
  final EnrollmentDetail? preview;
  final EnrollmentSummary? createdEnrollmentSummary;
  final EnrollmentSummary? updatedEnrollmentSummary;
  final String? errorMessage;

  const EnrollmentState({
    required this.createStatus,
    required this.statusUpdateStatus,
    required this.summariesStatus,
    required this.detailStatus,
    required this.previewStatus,
    required this.summaries,
    required this.summariesPage,
    required this.summariesSize,
    required this.summariesTotalElements,
    required this.summariesTotalPages,
    required this.summariesQueryType,
    required this.lastSummariesQuery,
    required this.detail,
    required this.preview,
    required this.createdEnrollmentSummary,
    required this.updatedEnrollmentSummary,
    required this.errorMessage,
  });

  const EnrollmentState.initial()
    : createStatus = EnrollmentLoadStatus.initial,
      statusUpdateStatus = EnrollmentLoadStatus.initial,
      summariesStatus = EnrollmentLoadStatus.initial,
      detailStatus = EnrollmentLoadStatus.initial,
      previewStatus = EnrollmentLoadStatus.initial,
      summaries = const <EnrollmentSummary>[],
      summariesPage = 0,
      summariesSize = 20,
      summariesTotalElements = 0,
      summariesTotalPages = 0,
      summariesQueryType = null,
      lastSummariesQuery = null,
      detail = null,
      preview = null,
      createdEnrollmentSummary = null,
      updatedEnrollmentSummary = null,
      errorMessage = null;

  EnrollmentState copyWith({
    EnrollmentLoadStatus? createStatus,
    EnrollmentLoadStatus? statusUpdateStatus,
    EnrollmentLoadStatus? summariesStatus,
    EnrollmentLoadStatus? detailStatus,
    EnrollmentLoadStatus? previewStatus,
    List<EnrollmentSummary>? summaries,
    int? summariesPage,
    int? summariesSize,
    int? summariesTotalElements,
    int? summariesTotalPages,
    Object? summariesQueryType = _undefined,
    Object? lastSummariesQuery = _undefined,
    Object? detail = _undefined,
    Object? preview = _undefined,
    Object? createdEnrollmentSummary = _undefined,
    Object? updatedEnrollmentSummary = _undefined,
    Object? errorMessage = _undefined,
  }) {
    return EnrollmentState(
      createStatus: createStatus ?? this.createStatus,
      statusUpdateStatus: statusUpdateStatus ?? this.statusUpdateStatus,
      summariesStatus: summariesStatus ?? this.summariesStatus,
      detailStatus: detailStatus ?? this.detailStatus,
      previewStatus: previewStatus ?? this.previewStatus,
      summaries: summaries ?? this.summaries,
      summariesPage: summariesPage ?? this.summariesPage,
      summariesSize: summariesSize ?? this.summariesSize,
      summariesTotalElements:
          summariesTotalElements ?? this.summariesTotalElements,
      summariesTotalPages: summariesTotalPages ?? this.summariesTotalPages,
      summariesQueryType: identical(summariesQueryType, _undefined)
          ? this.summariesQueryType
          : summariesQueryType as EnrollmentSummaryQueryType?,
      lastSummariesQuery: identical(lastSummariesQuery, _undefined)
          ? this.lastSummariesQuery
          : lastSummariesQuery as EnrollmentSummariesQuery?,
      detail: identical(detail, _undefined)
          ? this.detail
          : detail as EnrollmentDetail?,
      preview: identical(preview, _undefined)
          ? this.preview
          : preview as EnrollmentDetail?,
      createdEnrollmentSummary:
          identical(createdEnrollmentSummary, _undefined)
          ? this.createdEnrollmentSummary
          : createdEnrollmentSummary as EnrollmentSummary?,
      updatedEnrollmentSummary:
          identical(updatedEnrollmentSummary, _undefined)
          ? this.updatedEnrollmentSummary
          : updatedEnrollmentSummary as EnrollmentSummary?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    createStatus,
    statusUpdateStatus,
    summariesStatus,
    detailStatus,
    previewStatus,
    summaries,
    summariesPage,
    summariesSize,
    summariesTotalElements,
    summariesTotalPages,
    summariesQueryType,
    lastSummariesQuery,
    detail,
    preview,
    createdEnrollmentSummary,
    updatedEnrollmentSummary,
    errorMessage,
  ];
}
