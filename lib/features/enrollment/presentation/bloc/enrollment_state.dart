part of 'enrollment_bloc.dart';

const _undefined = Object();

class EnrollmentState extends Equatable {
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
  final EnrollmentErrorType? summariesErrorType;
  final String? errorMessage;

  const EnrollmentState({
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
    required this.summariesErrorType,
    required this.errorMessage,
  });

  const EnrollmentState.initial()
    : summariesStatus = EnrollmentLoadStatus.initial,
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
      summariesErrorType = null,
      errorMessage = null;

  EnrollmentState copyWith({
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
    Object? summariesErrorType = _undefined,
    Object? errorMessage = _undefined,
  }) {
    return EnrollmentState(
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
      summariesErrorType: identical(summariesErrorType, _undefined)
          ? this.summariesErrorType
          : summariesErrorType as EnrollmentErrorType?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
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
    summariesErrorType,
    errorMessage,
  ];
}
