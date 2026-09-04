part of 'fee_control_dashboard_bloc.dart';

const _undefined = Object();

class FeeControlDashboardState extends Equatable {
  // ── Natures de frais offertes à la sélection ───────────────────────────────

  final EnrollmentLoadStatus feeCodesStatus;

  /// Codes de nature, triés. **Jamais de libellé** : le rendu les nomme par
  /// `localizedFeeLabel`.
  final List<String> feeCodes;

  // ── Position de la population sur le frais interrogé ───────────────────────

  final EnrollmentLoadStatus status;
  final FeeControlDashboardSummary summary;

  final EnrollmentErrorType? errorType;
  final String? errorMessage;

  /// Ce dont [summary] est le résultat. `null` tant qu'aucune lecture n'a
  /// abouti — ce qui distingue « rien demandé » de « demandé, rien trouvé ».
  final FeeControlDashboardQuery? lastQuery;

  /// Inscrits du périmètre qui **ne portent pas ce frais**.
  ///
  /// `null` quand on ne sait pas : lecture pas encore faite, ou échouée. C'est
  /// délibérément distinct de `0` — « personne n'est hors facturation » et « on
  /// n'a pas pu vérifier » n'autorisent pas le même silence.
  ///
  /// **Jamais dans le taux.** Un élève sans créance de ce frais n'est pas un
  /// mauvais payeur : il n'est pas facturé. Le compter au dénominateur ferait
  /// chuter le taux d'une classe pour une raison qui n'a rien à voir avec le
  /// recouvrement.
  final int? unbilled;

  // ── Niveau déplié en classes ───────────────────────────────────────────────

  /// Niveau actuellement ouvert, `null` si tout est replié.
  final String? expandedLevelId;

  final EnrollmentLoadStatus classesStatus;

  /// Classes du niveau ouvert, la ligne des non-répartis en dernier.
  final List<FeeControlClassRow> classes;

  /// Vrai quand le niveau ouvert n'a **aucune classe** dans le référentiel
  /// local. Deux causes derrière ce vide, et l'écran doit les distinguer : la
  /// composition n'est pas descendue sur l'appareil, ou ce niveau n'est
  /// réellement pas découpé en classes. Le rendu tranche avec le droit
  /// `classroom.read`, qu'il est seul à connaître.
  final bool classroomsMissing;

  const FeeControlDashboardState({
    this.feeCodesStatus = EnrollmentLoadStatus.initial,
    this.feeCodes = const <String>[],
    this.status = EnrollmentLoadStatus.initial,
    this.summary = FeeControlDashboardSummary.empty,
    this.errorType,
    this.errorMessage,
    this.lastQuery,
    this.unbilled,
    this.expandedLevelId,
    this.classesStatus = EnrollmentLoadStatus.initial,
    this.classes = const <FeeControlClassRow>[],
    this.classroomsMissing = false,
  });

  const FeeControlDashboardState.initial() : this();

  /// Vrai quand une lecture a abouti sans trouver un seul élève concerné —
  /// l'état vide de l'écran, à ne pas confondre avec l'écran encore vierge.
  bool get hasEmptyResult =>
      status == EnrollmentLoadStatus.success && summary.isEmpty;

  FeeControlDashboardState copyWith({
    EnrollmentLoadStatus? feeCodesStatus,
    List<String>? feeCodes,
    EnrollmentLoadStatus? status,
    FeeControlDashboardSummary? summary,
    Object? errorType = _undefined,
    Object? errorMessage = _undefined,
    Object? lastQuery = _undefined,
    Object? unbilled = _undefined,
    Object? expandedLevelId = _undefined,
    EnrollmentLoadStatus? classesStatus,
    List<FeeControlClassRow>? classes,
    bool? classroomsMissing,
  }) => FeeControlDashboardState(
    feeCodesStatus: feeCodesStatus ?? this.feeCodesStatus,
    feeCodes: feeCodes ?? this.feeCodes,
    status: status ?? this.status,
    summary: summary ?? this.summary,
    errorType: identical(errorType, _undefined)
        ? this.errorType
        : errorType as EnrollmentErrorType?,
    errorMessage: identical(errorMessage, _undefined)
        ? this.errorMessage
        : errorMessage as String?,
    lastQuery: identical(lastQuery, _undefined)
        ? this.lastQuery
        : lastQuery as FeeControlDashboardQuery?,
    unbilled: identical(unbilled, _undefined)
        ? this.unbilled
        : unbilled as int?,
    expandedLevelId: identical(expandedLevelId, _undefined)
        ? this.expandedLevelId
        : expandedLevelId as String?,
    classesStatus: classesStatus ?? this.classesStatus,
    classes: classes ?? this.classes,
    classroomsMissing: classroomsMissing ?? this.classroomsMissing,
  );

  @override
  List<Object?> get props => [
    feeCodesStatus,
    feeCodes,
    status,
    summary,
    errorType,
    errorMessage,
    lastQuery,
    unbilled,
    expandedLevelId,
    classesStatus,
    classes,
    classroomsMissing,
  ];
}
