part of 'fee_control_bloc.dart';

const _undefined = Object();

class FeeControlState extends Equatable {
  // ── Grille tarifaire du niveau sélectionné ─────────────────────────────────

  final EnrollmentLoadStatus tariffsStatus;
  final List<LocalFeeTariff> tariffs;

  /// Vrai quand la grille est absente **de l'appareil** pour l'année, et non
  /// simplement vide pour ce niveau. Deux causes qui se ressemblent à l'écran
  /// et pas au guichet : « ce niveau n'a pas de frais » est une information,
  /// « la grille n'est pas descendue » appelle une synchronisation.
  final bool feeGridMissing;

  // ── Classes du niveau sélectionné ──────────────────────────────────────────

  final EnrollmentLoadStatus classroomsStatus;
  final List<OfflineClassroom> classrooms;

  // ── Résultats ──────────────────────────────────────────────────────────────

  final EnrollmentLoadStatus status;
  final List<FeeControlRow> rows;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  /// Élèves inscrits trouvés dans la classe, avant croisement avec le frais.
  final int studentsInScope;

  /// Répartition par statut des élèves qui portent réellement ce frais —
  /// alimente le bandeau de synthèse. `breakdown.total` vaut le nombre d'élèves
  /// concernés : son écart avec [studentsInScope] distingue « la classe ne porte
  /// pas ce frais » de « personne ne correspond au statut demandé ».
  final FeeControlBreakdown breakdown;

  /// Taille du roster local de la classe demandée, ou `null` si la recherche
  /// portait sur tout le niveau. `0` distingue « le roster n'est pas descendu
  /// sur cet appareil » de « la classe existe mais aucun de ses élèves n'a de
  /// dossier local » — deux pannes qui donnent la même liste vide et appellent
  /// deux gestes différents.
  final int? classroomRosterSize;

  final EnrollmentErrorType? errorType;
  final String? errorMessage;
  final FeeControlQuery? lastQuery;

  const FeeControlState({
    this.tariffsStatus = EnrollmentLoadStatus.initial,
    this.tariffs = const <LocalFeeTariff>[],
    this.feeGridMissing = false,
    this.classroomsStatus = EnrollmentLoadStatus.initial,
    this.classrooms = const <OfflineClassroom>[],
    this.status = EnrollmentLoadStatus.initial,
    this.rows = const <FeeControlRow>[],
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
    this.totalElements = 0,
    this.totalPages = 0,
    this.studentsInScope = 0,
    this.breakdown = const FeeControlBreakdown(),
    this.classroomRosterSize,
    this.errorType,
    this.errorMessage,
    this.lastQuery,
  });

  const FeeControlState.initial() : this();

  /// Vrai tant qu'aucune recherche n'a été lancée → carte d'invitation.
  bool get hasSearched => lastQuery != null;

  FeeControlState copyWith({
    EnrollmentLoadStatus? tariffsStatus,
    List<LocalFeeTariff>? tariffs,
    bool? feeGridMissing,
    EnrollmentLoadStatus? classroomsStatus,
    List<OfflineClassroom>? classrooms,
    EnrollmentLoadStatus? status,
    List<FeeControlRow>? rows,
    int? page,
    int? size,
    int? totalElements,
    int? totalPages,
    int? studentsInScope,
    FeeControlBreakdown? breakdown,
    Object? classroomRosterSize = _undefined,
    Object? errorType = _undefined,
    Object? errorMessage = _undefined,
    Object? lastQuery = _undefined,
  }) {
    return FeeControlState(
      tariffsStatus: tariffsStatus ?? this.tariffsStatus,
      tariffs: tariffs ?? this.tariffs,
      feeGridMissing: feeGridMissing ?? this.feeGridMissing,
      classroomsStatus: classroomsStatus ?? this.classroomsStatus,
      classrooms: classrooms ?? this.classrooms,
      status: status ?? this.status,
      rows: rows ?? this.rows,
      page: page ?? this.page,
      size: size ?? this.size,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      studentsInScope: studentsInScope ?? this.studentsInScope,
      breakdown: breakdown ?? this.breakdown,
      classroomRosterSize: identical(classroomRosterSize, _undefined)
          ? this.classroomRosterSize
          : classroomRosterSize as int?,
      errorType: identical(errorType, _undefined)
          ? this.errorType
          : errorType as EnrollmentErrorType?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
      lastQuery: identical(lastQuery, _undefined)
          ? this.lastQuery
          : lastQuery as FeeControlQuery?,
    );
  }

  /// Transition « page de résultats servie ». Les deux compteurs ne sont passés
  /// qu'au chargement : une simple pagination rejoue la même population.
  FeeControlState withPage({
    required FeeControlQuery query,
    required ClientPage<FeeControlRow> page,
    int? studentsInScope,
    FeeControlBreakdown? breakdown,
    Object? classroomRosterSize = _undefined,
  }) => copyWith(
    status: EnrollmentLoadStatus.success,
    rows: page.content,
    page: page.page,
    size: page.size,
    totalElements: page.totalElements,
    totalPages: page.totalPages,
    studentsInScope: studentsInScope,
    breakdown: breakdown,
    classroomRosterSize: classroomRosterSize,
    lastQuery: query.copyWithPage(page.page),
    errorType: null,
    errorMessage: null,
  );

  /// Transition « échec » : la liste est vidée, pas conservée sous la requête
  /// qui a échoué.
  FeeControlState withFailure({
    required EnrollmentErrorType errorType,
    required String? errorMessage,
  }) => copyWith(
    status: EnrollmentLoadStatus.failure,
    rows: const <FeeControlRow>[],
    totalElements: 0,
    totalPages: 0,
    studentsInScope: 0,
    breakdown: const FeeControlBreakdown(),
    classroomRosterSize: null,
    errorType: errorType,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    tariffsStatus,
    tariffs,
    feeGridMissing,
    classroomsStatus,
    classrooms,
    status,
    rows,
    page,
    size,
    totalElements,
    totalPages,
    studentsInScope,
    breakdown,
    classroomRosterSize,
    errorType,
    errorMessage,
    lastQuery,
  ];
}
