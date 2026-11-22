part of 'fee_control_bloc.dart';

const _undefined = Object();

class FeeControlState extends Equatable {
  // ── Catalogue : natures de l'année et classes de l'année ────────────────

  final EnrollmentLoadStatus catalogStatus;

  /// Les natures facturées sur l'année, avec leur(s) devise(s), la plus portée
  /// d'abord.
  final List<FeeNature> natures;

  /// Toutes les classes de l'année — le champ Classe unique, groupé par cycle.
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

  /// Attendu et **encaissé** de toute la classe sur les frais retenus, par
  /// devise — la cinquième carte de la rangée de compteurs. Deux sacs, jamais
  /// deux nombres : en sélection mixte, chacun s'écrit sur deux lignes.
  final MoneyBag expected;
  final MoneyBag collected;

  /// Devises **présentes** dans les créances de la classe sur la sélection —
  /// et non celles des frais cochés : un même frais peut être en dollars au
  /// primaire et en francs au secondaire. Deux devises ⇒ « a payé au moins… »
  /// indisponible, tri par situation.
  final Set<String> currencies;

  /// Taille du roster local de la classe demandée, ou `null` pour la rubrique
  /// « Non affectés », qui n'a pas de roster. `0` distingue « le roster n'est pas descendu
  /// sur cet appareil » de « la classe existe mais aucun de ses élèves n'a de
  /// dossier local » — deux pannes qui donnent la même liste vide et appellent
  /// deux gestes différents.
  final int? classroomRosterSize;

  final EnrollmentErrorType? errorType;
  final String? errorMessage;
  final FeeControlQuery? lastQuery;

  const FeeControlState({
    this.catalogStatus = EnrollmentLoadStatus.initial,
    this.natures = const <FeeNature>[],
    this.classrooms = const <OfflineClassroom>[],
    this.status = EnrollmentLoadStatus.initial,
    this.rows = const <FeeControlRow>[],
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
    this.totalElements = 0,
    this.totalPages = 0,
    this.studentsInScope = 0,
    this.breakdown = const FeeControlBreakdown(),
    this.expected = MoneyBag.empty,
    this.collected = MoneyBag.empty,
    this.currencies = const <String>{},
    this.classroomRosterSize,
    this.errorType,
    this.errorMessage,
    this.lastQuery,
  });

  const FeeControlState.initial() : this();

  /// Vrai tant qu'aucune recherche n'a été lancée → carte d'invitation.
  bool get hasSearched => lastQuery != null;

  /// Une seule devise dans la classe : « a payé au moins… » est offert.
  bool get atLeastAvailable => currencies.length <= 1;

  /// L'unique devise de la classe, ou `null` (mixte, ou pas encore lu).
  String? get soleCurrency => currencies.length == 1 ? currencies.first : null;

  FeeControlState copyWith({
    EnrollmentLoadStatus? catalogStatus,
    List<FeeNature>? natures,
    List<OfflineClassroom>? classrooms,
    EnrollmentLoadStatus? status,
    List<FeeControlRow>? rows,
    int? page,
    int? size,
    int? totalElements,
    int? totalPages,
    int? studentsInScope,
    FeeControlBreakdown? breakdown,
    MoneyBag? expected,
    MoneyBag? collected,
    Set<String>? currencies,
    Object? classroomRosterSize = _undefined,
    Object? errorType = _undefined,
    Object? errorMessage = _undefined,
    Object? lastQuery = _undefined,
  }) {
    return FeeControlState(
      catalogStatus: catalogStatus ?? this.catalogStatus,
      natures: natures ?? this.natures,
      classrooms: classrooms ?? this.classrooms,
      status: status ?? this.status,
      rows: rows ?? this.rows,
      page: page ?? this.page,
      size: size ?? this.size,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      studentsInScope: studentsInScope ?? this.studentsInScope,
      breakdown: breakdown ?? this.breakdown,
      expected: expected ?? this.expected,
      collected: collected ?? this.collected,
      currencies: currencies ?? this.currencies,
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
    MoneyBag? expected,
    MoneyBag? collected,
    Set<String>? currencies,
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
    expected: expected,
    collected: collected,
    currencies: currencies,
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
    expected: MoneyBag.empty,
    collected: MoneyBag.empty,
    currencies: const <String>{},
    classroomRosterSize: null,
    errorType: errorType,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    catalogStatus,
    natures,
    classrooms,
    status,
    rows,
    page,
    size,
    totalElements,
    totalPages,
    studentsInScope,
    breakdown,
    expected,
    collected,
    currencies,
    classroomRosterSize,
    errorType,
    errorMessage,
    lastQuery,
  ];
}
