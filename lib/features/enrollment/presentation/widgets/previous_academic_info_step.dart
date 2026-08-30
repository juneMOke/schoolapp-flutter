import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/widgets/enrollment_draft_step_save_listener.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/academic_info_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PreviousAcademicInfoStep extends StatefulWidget {
  final EnrollmentSchoolDetail enrollmentDetail;
  final String enrollmentId;

  /// Type du dossier (`NEW_ENROLLMENT` / `RE_ENROLLMENT` / `PRE_ENROLLMENT`).
  /// Il ne sert QU'À décider si « ancien élève » est un fait acquis (RE) ou une
  /// déclaration du guichet — la valeur elle-même reste portée par le dossier,
  /// et les deux notions restent distinctes.
  final String enrollmentType;

  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final VoidCallback? onRefreshRequested;
  final bool isEditable;
  final EnrollmentStepSubmitController? stepController;

  const PreviousAcademicInfoStep({
    super.key,
    required this.enrollmentDetail,
    required this.enrollmentId,
    this.enrollmentType = 'NEW_ENROLLMENT',
    this.showInlineSaveButton = true,
    this.flowStepIndex,
    this.onRefreshRequested,
    this.isEditable = true,
    this.stepController,
  });

  @override
  State<PreviousAcademicInfoStep> createState() =>
      PreviousAcademicInfoStepState();
}

class PreviousAcademicInfoStepState extends State<PreviousAcademicInfoStep> {
  late final TextEditingController _prevSchoolController;
  late final TextEditingController _prevRateController;
  late final TextEditingController _prevRankController;

  // Année scolaire, cycle & niveau : valeurs sélectionnées dans les dropdowns
  String? _selectedYear;
  String? _selectedCycle;
  String? _selectedLevel;

  /// Tri-état : `null` = personne ne l'a dit. Un dossier neuf part de là, et
  /// n'affiche donc ni « Oui » ni « Non ».
  bool? _validatedPreviousYear;

  /// « Ancien élève de l'école », déclaré au guichet.
  bool _formerStudent = false;
  // Devient true dès que l'utilisateur bascule le sélecteur à la main : la
  // valeur ne suit alors plus automatiquement la moyenne saisie.
  bool _validatedPreviousYearManuallySet = false;

  /// Moyenne telle qu'elle était au dernier passage de la déduction — c'est
  /// elle qui décide si la déduction a lieu d'être rejouée. Réancrée à chaque
  /// hydratation, pour qu'un dossier rouvert ne déduise rien de ce qu'il
  /// affiche déjà.
  String _lastRateForDerivation = '';

  static const double _validatedYearRateThreshold = 50;

  String _initialPrevYear = '';
  String _initialPrevSchool = '';
  String _initialPrevCycle = '';
  String _initialPrevLevel = '';
  String _initialPrevRate = '';
  String _initialPrevRank = '';
  bool? _initialValidatedPreviousYear;
  bool _initialFormerStudent = false;

  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;
  bool _isHydratingFromDetail = false;
  bool _awaitingDraftSave = false;

  // Catalogue des cycles d'éducation
  EducationCyclesCatalog? _cyclesCatalog;
  bool _isCatalogLoading = true;

  bool get _canSave => _stepState.canSave;

  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

  // ---------------------------------------------------------------------------
  // Dropdown options
  // ---------------------------------------------------------------------------

  /// Génère les 3 années scolaires les plus récentes selon l'année en cours.
  /// Format : "YYYY-YYYY" (ex. "2025-2026").
  static List<String> _buildYearOptions() {
    final currentYear = DateTime.now().year;
    return List<String>.unmodifiable([
      '${currentYear - 1}-$currentYear',
      '${currentYear - 2}-${currentYear - 1}',
      '${currentYear - 3}-${currentYear - 2}',
    ]);
  }

  /// Résout [rawYear] parmi [options] en comparaison normalisée (ignore espaces
  /// et tirets multiples).
  ///
  /// **Rend `null` quand le dossier ne dit rien**, et jamais `options.first`.
  /// Le bloc « école précédente » étant facultatif, une liste qui se remplit
  /// seule écrirait en base une année que personne n'a choisie — la même
  /// fabrication que le serveur a cessé de produire, déplacée dans l'écran. Un
  /// libellé illisible est conservé tel quel plutôt que remplacé : il vient
  /// d'une vraie saisie, et le premier élément du catalogue serait une réponse
  /// inventée à sa place.
  static String? _resolveYear(String? rawYear, List<String> options) {
    if (rawYear == null || rawYear.trim().isEmpty) return null;

    final candidate = _normalizeYearKey(rawYear);
    for (final opt in options) {
      if (_normalizeYearKey(opt) == candidate) return opt;
    }
    return rawYear.trim();
  }

  static String _normalizeYearKey(String value) =>
      value.replaceAll(RegExp(r'[\s\-–]+'), '-').trim();

  List<String> get _yearOptions => _buildYearOptions();

  List<String> get _cycleOptions {
    final catalog = _cyclesCatalog;
    if (catalog == null) {
      final c = _selectedCycle;
      return c != null && c.isNotEmpty ? [c] : const [];
    }
    return catalog.cycleNames;
  }

  List<String> get _levelOptions {
    final catalog = _cyclesCatalog;
    final cycle = _selectedCycle;
    if (catalog == null || cycle == null || cycle.isEmpty) {
      final l = _selectedLevel;
      return l != null && l.isNotEmpty ? [l] : const [];
    }
    return catalog.yearsForCycle(cycle);
  }

  // ---------------------------------------------------------------------------
  // Normalisation helpers (rate & rank)
  // ---------------------------------------------------------------------------

  String _normalizeRate(String rawValue) {
    final trimmed = rawValue.trim();
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return trimmed;
    return _normalizeRateFromDouble(parsed);
  }

  String _normalizeRateFromDouble(double? value) {
    // `null` (rien de renseigné) et `<= 0` rendent tous deux un champ vide,
    // mais pour des raisons distinctes : le premier n'a jamais été saisi, le
    // second est une valeur hors domaine héritée. Aucun des deux n'est une
    // moyenne à afficher.
    if (value == null || value <= 0) return '';
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    var normalized = value.toStringAsFixed(6);
    normalized = normalized.replaceFirst(RegExp(r'0+$'), '');
    normalized = normalized.replaceFirst(RegExp(r'\.$'), '');
    return normalized;
  }

  String _normalizeRank(String rawValue) {
    final trimmed = rawValue.trim();
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return trimmed;
    return parsed.toString();
  }

  String _normalizeRankFromInt(int? value) {
    if (value == null) return '';
    return value.toString();
  }

  void submitForm() => _onSave();

  void _emitStepState() {
    final flowStepIndex = widget.flowStepIndex;
    if (flowStepIndex != null && mounted) {
      context.read<EnrollmentStepperFlowBloc>().add(
        EnrollmentStepperStepStateReported(
          step: flowStepIndex,
          stepState: _stepState,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _prevSchoolController = TextEditingController();
    _prevRateController = TextEditingController();
    _prevRankController = TextEditingController();

    _syncFromEnrollmentDetail(widget.enrollmentDetail, resetSnapshot: true);

    _prevSchoolController.addListener(_onFieldChanged);
    _prevRateController.addListener(_onFieldChanged);
    _prevRankController.addListener(_onFieldChanged);

    _loadCyclesCatalog();

    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });

    widget.stepController?.bind(submitForm);
  }

  Future<void> _loadCyclesCatalog() async {
    try {
      final catalog = await EducationCyclesCatalog.load();
      if (!mounted) return;
      setState(() {
        _cyclesCatalog = catalog;
        _isCatalogLoading = false;
      });
      _syncCycleAndLevelWithCatalog(catalog);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCatalogLoading = false);
    }
  }

  /// Aligne cycle & niveau sur le catalogue une fois celui-ci chargé.
  ///
  /// **Reconnaît, ne remplit pas.** Une valeur déjà portée par le dossier est
  /// rapprochée de son entrée du catalogue (casse, accents) ; une valeur
  /// absente le reste. Ce sont deux gestes qu'il ne faut pas confondre :
  /// retomber sur `firstCycle` faisait choisir « Maternelle · 1ʳᵉ année » à la
  /// place du guichet, sur un bloc qui n'est plus obligatoire.
  void _syncCycleAndLevelWithCatalog(EducationCyclesCatalog catalog) {
    final rawCycle = _selectedCycle ?? '';
    final rawLevel = _selectedLevel ?? '';

    final resolvedCycle = rawCycle.isEmpty
        ? null
        : catalog.resolveCycle(rawCycle)?.nom ?? rawCycle;

    final resolvedLevel = resolvedCycle == null || rawLevel.isEmpty
        ? null
        : catalog.resolveLevel(resolvedCycle, rawLevel) ?? rawLevel;

    if (_selectedCycle != resolvedCycle || _selectedLevel != resolvedLevel) {
      setState(() {
        _selectedCycle = resolvedCycle;
        _selectedLevel = resolvedLevel;
      });
      _recomputeFormState();
    }
  }

  void _syncFromEnrollmentDetail(
    EnrollmentSchoolDetail detail, {
    required bool resetSnapshot,
  }) {
    _isHydratingFromDetail = true;
    try {
      _selectedYear = _resolveYear(
        detail.previousAcademicYear,
        _buildYearOptions(),
      );
      _prevSchoolController.text = detail.previousSchoolName;
      _selectedCycle = detail.previousSchoolLevelGroup.isNotEmpty
          ? detail.previousSchoolLevelGroup
          : null;
      _selectedLevel = detail.previousSchoolLevel.isNotEmpty
          ? detail.previousSchoolLevel
          : null;
      _prevRateController.text = _normalizeRateFromDouble(detail.previousRate);
      _prevRankController.text = _normalizeRankFromInt(detail.previousRank);
      _validatedPreviousYear = detail.validatedPreviousYear;
      _validatedPreviousYearManuallySet = false;
      _lastRateForDerivation = _prevRateController.text.trim();
      // En réinscription, le fait est acquis : l'élève vient d'un dossier N-1
      // de cette école. Ailleurs, c'est le dossier qui parle.
      _formerStudent = _isReEnrollment || detail.formerStudent;
    } finally {
      _isHydratingFromDetail = false;
    }

    if (resetSnapshot) {
      _initialPrevYear = _selectedYear ?? '';
      _initialPrevSchool = detail.previousSchoolName.trim();
      _initialPrevCycle = detail.previousSchoolLevelGroup.trim();
      _initialPrevLevel = detail.previousSchoolLevel.trim();
      _initialPrevRate = _normalizeRateFromDouble(detail.previousRate);
      _initialPrevRank = _normalizeRankFromInt(detail.previousRank);
      _initialValidatedPreviousYear = detail.validatedPreviousYear;
      _initialFormerStudent = _formerStudent;
    }
  }

  void _markCurrentAsSavedSnapshot() {
    _initialPrevYear = _selectedYear ?? '';
    _initialPrevSchool = _prevSchoolController.text.trim();
    _initialPrevCycle = _selectedCycle?.trim() ?? '';
    _initialPrevLevel = _selectedLevel?.trim() ?? '';
    _initialPrevRate = _normalizeRate(_prevRateController.text);
    _initialPrevRank = _normalizeRank(_prevRankController.text);
    _initialValidatedPreviousYear = _validatedPreviousYear;
    _initialFormerStudent = _formerStudent;
  }

  /// Réinscription : la case est vraie et verrouillée. Le dossier vient d'une
  /// inscription de l'année précédente DANS CETTE ÉCOLE — ce n'est plus une
  /// déclaration du guichet mais un fait que le parcours établit.
  ///
  /// La préinscription, elle, ne dit rien : un préinscrit est un futur élève,
  /// pas un ancien. La case y reste décochée et modifiable — même repli que
  /// `EnrollmentType.formerStudentOrDefault` côté serveur.
  bool get _isReEnrollment => widget.enrollmentType == 'RE_ENROLLMENT';

  @override
  void didUpdateWidget(covariant PreviousAcademicInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stepController != widget.stepController) {
      oldWidget.stepController?.unbind(submitForm);
      widget.stepController?.bind(submitForm);
    }

    if (oldWidget.enrollmentDetail != widget.enrollmentDetail) {
      _syncFromEnrollmentDetail(widget.enrollmentDetail, resetSnapshot: true);
      final catalog = _cyclesCatalog;
      if (catalog != null) {
        _syncCycleAndLevelWithCatalog(catalog);
      }
      _showValidationHints = false;
      _isSaving = false;
      _recomputeFormState(notifyParent: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _emitStepState();
      });
    }
  }

  @override
  void dispose() {
    widget.stepController?.unbind(submitForm);
    _prevSchoolController.removeListener(_onFieldChanged);
    _prevRateController.removeListener(_onFieldChanged);
    _prevRankController.removeListener(_onFieldChanged);
    _prevSchoolController.dispose();
    _prevRateController.dispose();
    _prevRankController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onFieldChanged() {
    if (_isHydratingFromDetail) return;
    _applyAutoValidatedYearFromRate();
    _recomputeFormState();
    if (_showValidationHints && _isValid) {
      setState(() => _showValidationHints = false);
    }
  }

  // Par défaut, une moyenne > 50 vaut année validée, sinon non validée.
  // Ne s'applique plus une fois que l'utilisateur a tranché lui-même via le
  // sélecteur (cf. onValidatedChanged).
  //
  // **La déduction ne se déclenche QUE si la moyenne vient de changer.** Elle
  // était rejouée à chaque frappe, dans n'importe quel champ : depuis que la
  // moyenne est facultative, un dossier peut porter « Année validée = Oui »
  // sans moyenne — et corriger une faute de frappe dans le nom de l'école
  // suffisait alors à effacer ce verdict, puisque `parsedRate == null` en
  // déduisait « non renseignée ». Le dossier partait vidé d'une déclaration
  // que personne n'avait retirée, et le calcul automatique de la classe cible
  // s'arrêtait dans la foulée.
  //
  // Sans moyenne, aucune déduction : effacer la moyenne emporte bien ce
  // qu'elle avait déduit — mais seul un changement de MOYENNE y touche.
  void _applyAutoValidatedYearFromRate() {
    final rawRate = _prevRateController.text.trim();
    if (rawRate == _lastRateForDerivation) return;
    _lastRateForDerivation = rawRate;

    if (_validatedPreviousYearManuallySet) return;
    final parsedRate = double.tryParse(rawRate);
    final computed = parsedRate == null
        ? null
        : parsedRate > _validatedYearRateThreshold;
    if (computed != _validatedPreviousYear) {
      setState(() => _validatedPreviousYear = computed);
    }
  }

  void _onYearChanged(String? year) {
    setState(() => _selectedYear = year);
    _recomputeFormState();
  }

  void _onCycleChanged(String? cycle) {
    setState(() {
      _selectedCycle = cycle;
      // Le niveau repart à vide : changer de cycle invalide le niveau choisi,
      // et en proposer un d'office le choisirait à la place du guichet.
      _selectedLevel = null;
    });
    _recomputeFormState();
    if (_showValidationHints && _isValid) {
      setState(() => _showValidationHints = false);
    }
  }

  void _onLevelChanged(String? level) {
    setState(() => _selectedLevel = level);
    _recomputeFormState();
    if (_showValidationHints && _isValid) {
      setState(() => _showValidationHints = false);
    }
  }

  void _recomputeFormState({bool notifyParent = true}) {
    final prevYear = _selectedYear?.trim() ?? '';
    final prevSchool = _prevSchoolController.text.trim();
    final prevCycle = _selectedCycle?.trim() ?? '';
    final prevLevel = _selectedLevel?.trim() ?? '';
    final prevRate = _normalizeRate(_prevRateController.text);
    final prevRank = _normalizeRank(_prevRankController.text);

    // **Plus aucune complétude exigée** : le bloc entier est facultatif, et un
    // enfant qui n'a jamais été scolarisé doit pouvoir traverser l'étape sans
    // rien écrire. Ne reste que la cohérence de ce qui EST saisi — une moyenne
    // doit être un nombre entre 0 et 100, un rang un entier. Le champ vide est
    // valide ; le champ mal rempli ne l'est pas.
    final validNow = !_hasRateError && !_hasRankError;

    final dirtyNow =
        prevYear != _initialPrevYear ||
        prevSchool != _initialPrevSchool ||
        prevCycle != _initialPrevCycle ||
        prevLevel != _initialPrevLevel ||
        prevRate != _initialPrevRate ||
        prevRank != _initialPrevRank ||
        _validatedPreviousYear != _initialValidatedPreviousYear ||
        _formerStudent != _initialFormerStudent;

    if (_isValid != validNow || _isDirty != dirtyNow) {
      setState(() {
        _isValid = validNow;
        _isDirty = dirtyNow;
      });
      if (notifyParent) _emitStepState();
    } else if (notifyParent) {
      _emitStepState();
    }
  }

  void _onSavingChanged(bool saving) {
    if (_isSaving == saving) return;
    _isSaving = saving;
    _emitStepState();
  }

  /// Cause d'invalidité de la moyenne, ou `null` si elle est acceptable —
  /// **vide comprise**. Bornée à 0–100 : c'est une garde de saisie, le contrat
  /// serveur n'en pose aucune, et une moyenne à 850 % est plus sûrement une
  /// faute de frappe qu'un résultat.
  ///
  /// Rendue ici plutôt que dans `_recomputeFormState` : la validité, la liste
  /// des raisons et le message sous le champ doivent dire la même chose, et
  /// trois formulations séparées finissent toujours par diverger.
  String? _rateErrorOf(AppLocalizations l10n) {
    final raw = _prevRateController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null) return l10n.invalidNumberFieldError(l10n.averageLabel);
    if (parsed < 0 || parsed > 100) return l10n.averageOutOfRangeError;
    return null;
  }

  /// Idem pour le rang : vide est acceptable, illisible ne l'est pas.
  String? _rankErrorOf(AppLocalizations l10n) {
    final raw = _prevRankController.text.trim();
    if (raw.isEmpty) return null;
    if (int.tryParse(raw) == null) {
      return l10n.invalidNumberFieldError(l10n.rankingLabel);
    }
    return null;
  }

  /// Variantes sans localisation, pour `_recomputeFormState` qui n'a pas de
  /// `BuildContext` garanti : seule la PRÉSENCE d'une erreur y compte.
  bool get _hasRateError {
    final raw = _prevRateController.text.trim();
    if (raw.isEmpty) return false;
    final parsed = double.tryParse(raw);
    return parsed == null || parsed < 0 || parsed > 100;
  }

  bool get _hasRankError {
    final raw = _prevRankController.text.trim();
    return raw.isNotEmpty && int.tryParse(raw) == null;
  }

  List<String> _buildValidationErrors(AppLocalizations l10n) {
    // Aucune absence n'est signalée : le bloc est facultatif en entier.
    return <String>[?_rateErrorOf(l10n), ?_rankErrorOf(l10n)];
  }

  void _onSave() {
    if (!widget.isEditable) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_isValid) {
      final reasons = _buildValidationErrors(l10n);
      setState(() => _showValidationHints = true);
      AppSnackBar.showValidationErrors(
        context,
        title: l10n.academicInfoValidationReasonsTitle,
        reasons: reasons,
      );
      return;
    }
    if (!_isDirty) return;

    _dispatchDraftPreviousAcademic();
  }

  void _dispatchDraftPreviousAcademic() {
    _awaitingDraftSave = true;
    _onSavingChanged(true);
    context.read<EnrollmentOfflineBloc>().add(
      SaveDraftPreviousAcademicRequested(
        enrollmentId: widget.enrollmentId,
        previousSchoolName: _prevSchoolController.text.trim(),
        previousAcademicYear: _selectedYear,
        previousSchoolLevelGroup: _selectedCycle,
        previousSchoolLevel: _selectedLevel,
        previousRate: double.tryParse(_prevRateController.text.trim()),
        previousRank: int.tryParse(_prevRankController.text.trim()),
        validatedPreviousYear: _validatedPreviousYear,
        formerStudent: _formerStudent,
        transferReason: null,
      ),
    );
  }

  void _onDraftSaved() {
    _awaitingDraftSave = false;
    _markCurrentAsSavedSnapshot();
    _recomputeFormState();
    _onSavingChanged(false);
    if (_showValidationHints) {
      setState(() => _showValidationHints = false);
    }
    AppSnackBar.showSuccess(
      context,
      AppLocalizations.of(context)!.academicInfoSaveSuccess,
    );
    widget.onRefreshRequested?.call();
  }

  void _onDraftError(String message) {
    _awaitingDraftSave = false;
    _onSavingChanged(false);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showValidation = _showValidationHints || (_isDirty && !_isValid);

    final year = _selectedYear;
    final cycle = _selectedCycle;
    final level = _selectedLevel;

    return EnrollmentDraftStepSaveListener(
      enabled: true,
      isAwaiting: () => _awaitingDraftSave,
      onSaved: _onDraftSaved,
      onError: _onDraftError,
      child: PreviousAcademicInfoStepBody(
        yearOptions: _yearOptions,
        selectedYear: year,
        onYearChanged: _onYearChanged,
        prevSchoolController: _prevSchoolController,
        cycleOptions: _cycleOptions,
        levelOptions: _levelOptions,
        selectedCycle: cycle,
        selectedLevel: level,
        onCycleChanged: _onCycleChanged,
        onLevelChanged: _onLevelChanged,
        isCatalogLoading: _isCatalogLoading,
        prevRateController: _prevRateController,
        prevRankController: _prevRankController,
        validatedPreviousYear: _validatedPreviousYear,
        formerStudent: _formerStudent,
        formerStudentEditable: !_isReEnrollment,
        formerStudentChanged: _formerStudent != _initialFormerStudent,
        onFormerStudentChanged: (value) {
          setState(() => _formerStudent = value);
          _recomputeFormState();
        },
        showValidation: showValidation,
        isLoading: _isSaving,
        canSave: _canSave,
        showInlineSaveButton: widget.showInlineSaveButton,
        onSave: _onSave,
        isEditable: widget.isEditable,
        onValidatedChanged: (value) {
          setState(() {
            _validatedPreviousYear = value;
            _validatedPreviousYearManuallySet = true;
          });
          _recomputeFormState();
        },
        // Année, école, cycle et niveau ne portent plus d'erreur : les laisser
        // vides est un état légitime du dossier, pas un oubli à signaler.
        prevYearError: null,
        prevSchoolError: null,
        prevCycleError: null,
        prevLevelError: null,
        // Seule la saisie ILLISIBLE se signale — jamais la saisie absente.
        prevRateError: showValidation ? _rateErrorOf(l10n) : null,
        prevRankError: showValidation ? _rankErrorOf(l10n) : null,
        validatedPreviousYearChanged:
            _validatedPreviousYear != _initialValidatedPreviousYear,
      ),
    );
  }
}
