part of 'enrollment_local_list_bloc.dart';

const _undefined = Object();

/// État du listing LOCAL des inscriptions.
///
/// Il reprend **volontairement les mêmes noms de getters** que la moitié
/// « summaries » de `EnrollmentState` (statut, résumés, pagination, type/photo
/// de requête, erreur) afin que les widgets de résultats et les pages restent
/// inchangés lors de la bascule online → local.
class EnrollmentLocalListState extends Equatable {
  final EnrollmentLoadStatus summariesStatus;
  final List<EnrollmentSummary> summaries;
  final int summariesPage;
  final int summariesSize;
  final int summariesTotalElements;
  final int summariesTotalPages;
  final EnrollmentSummaryQueryType? summariesQueryType;
  final EnrollmentSummariesQuery? lastSummariesQuery;
  final EnrollmentErrorType? summariesErrorType;
  final String? errorMessage;

  /// Les élèves désactivés sont-ils montrés ? Oui par défaut ; la Première
  /// inscription les masque à l'ouverture (bascule « Afficher les
  /// désactivés »).
  final bool showSuspended;

  /// Élèves désactivés dans le résultat de la requête, montrés ou non.
  final int suspendedCount;

  const EnrollmentLocalListState({
    required this.summariesStatus,
    required this.summaries,
    required this.summariesPage,
    required this.summariesSize,
    required this.summariesTotalElements,
    required this.summariesTotalPages,
    required this.summariesQueryType,
    required this.lastSummariesQuery,
    required this.summariesErrorType,
    required this.errorMessage,
    this.showSuspended = true,
    this.suspendedCount = 0,
  });

  const EnrollmentLocalListState.initial()
    : summariesStatus = EnrollmentLoadStatus.initial,
      summaries = const <EnrollmentSummary>[],
      summariesPage = 0,
      summariesSize = AppConstants.enrollmentDefaultPageSize,
      summariesTotalElements = 0,
      summariesTotalPages = 0,
      summariesQueryType = null,
      lastSummariesQuery = null,
      summariesErrorType = null,
      errorMessage = null,
      showSuspended = true,
      suspendedCount = 0;

  EnrollmentLocalListState copyWith({
    EnrollmentLoadStatus? summariesStatus,
    List<EnrollmentSummary>? summaries,
    int? summariesPage,
    int? summariesSize,
    int? summariesTotalElements,
    int? summariesTotalPages,
    Object? summariesQueryType = _undefined,
    Object? lastSummariesQuery = _undefined,
    Object? summariesErrorType = _undefined,
    Object? errorMessage = _undefined,
    bool? showSuspended,
    int? suspendedCount,
  }) {
    return EnrollmentLocalListState(
      summariesStatus: summariesStatus ?? this.summariesStatus,
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
      summariesErrorType: identical(summariesErrorType, _undefined)
          ? this.summariesErrorType
          : summariesErrorType as EnrollmentErrorType?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
      showSuspended: showSuspended ?? this.showSuspended,
      suspendedCount: suspendedCount ?? this.suspendedCount,
    );
  }

  @override
  List<Object?> get props => [
    summariesStatus,
    summaries,
    summariesPage,
    summariesSize,
    summariesTotalElements,
    summariesTotalPages,
    summariesQueryType,
    lastSummariesQuery,
    summariesErrorType,
    errorMessage,
    showSuspended,
    suspendedCount,
  ];
}
