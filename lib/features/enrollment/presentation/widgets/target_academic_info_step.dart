import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/widgets/enrollment_draft_step_save_listener.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/target_school_level_resolver.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/academic_info_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TargetAcademicInfoStep extends StatefulWidget {
  final StudentDetail studentDetail;
  final EnrollmentSchoolDetail enrollmentDetail;
  final String studentId;
  final String enrollmentId;

  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final VoidCallback? onRefreshRequested;
  final bool isEditable;
  final EnrollmentStepSubmitController? stepController;

  const TargetAcademicInfoStep({
    super.key,
    required this.studentDetail,
    required this.enrollmentDetail,
    required this.studentId,
    required this.enrollmentId,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
    this.onRefreshRequested,
    this.isEditable = true,
    this.stepController,
  });

  @override
  State<TargetAcademicInfoStep> createState() => TargetAcademicInfoStepState();
}

class TargetAcademicInfoStepState extends State<TargetAcademicInfoStep> {
  late final TextEditingController _currYearController;
  late final TextEditingController _targetOptionController;

  late String _selectedSchoolLevelGroupId;
  late String _selectedSchoolLevelId;
  bool _bootstrapDefaultsApplied = false;

  // Devient true dès que l'utilisateur choisit lui-même le cycle/niveau
  // cible : le calcul auto (classe de l'année précédente → classe cible) ne
  // s'applique plus alors, y compris si le dossier n'a encore rien de
  // persisté (cf. pattern _validatedPreviousYearManuallySet de
  // PreviousAcademicInfoStep).
  bool _targetLevelManuallySet = false;

  // true tant que la valeur actuellement affichée provient du calcul auto
  // (et pas d'un choix manuel) — pilote uniquement le badge « Auto ».
  bool _targetLevelAutoFilled = false;

  String _initialSchoolLevelGroupId = '';
  String _initialSchoolLevelId = '';

  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;
  bool _awaitingDraftSave = false;

  bool get _canSave => _stepState.canSave;

  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

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

  @override
  void initState() {
    super.initState();

    _currYearController = TextEditingController();
    _targetOptionController = TextEditingController();

    _syncFromStudentDetail(widget.studentDetail, resetSnapshot: true);

    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });

    widget.stepController?.bind(submitForm);
  }

  void _syncFromStudentDetail(
    StudentDetail detail, {
    required bool resetSnapshot,
  }) {
    _selectedSchoolLevelGroupId = detail.schoolLevelGroup.id;
    _selectedSchoolLevelId = detail.schoolLevel.id;

    if (resetSnapshot) {
      _initialSchoolLevelGroupId = detail.schoolLevelGroup.id;
      _initialSchoolLevelId = detail.schoolLevel.id;
    }
  }

  void _markCurrentAsSavedSnapshot() {
    _initialSchoolLevelGroupId = _selectedSchoolLevelGroupId;
    _initialSchoolLevelId = _selectedSchoolLevelId;
  }

  @override
  void didUpdateWidget(covariant TargetAcademicInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stepController != widget.stepController) {
      oldWidget.stepController?.unbind(submitForm);
      widget.stepController?.bind(submitForm);
    }

    if (oldWidget.studentDetail != widget.studentDetail) {
      _syncFromStudentDetail(widget.studentDetail, resetSnapshot: true);
      _bootstrapDefaultsApplied = false;
      _targetLevelManuallySet = false;
      _targetLevelAutoFilled = false;
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
    _currYearController.dispose();
    _targetOptionController.dispose();
    super.dispose();
  }

  void _recomputeFormState({bool notifyParent = true}) {
    final currYear = _currYearController.text.trim();

    final validNow =
        currYear.isNotEmpty &&
        _selectedSchoolLevelGroupId.isNotEmpty &&
        _selectedSchoolLevelId.isNotEmpty;

    final dirtyNow =
        _selectedSchoolLevelGroupId != _initialSchoolLevelGroupId ||
        _selectedSchoolLevelId != _initialSchoolLevelId;

    if (_isValid != validNow || _isDirty != dirtyNow) {
      setState(() {
        _isValid = validNow;
        _isDirty = dirtyNow;
      });
      if (notifyParent) {
        _emitStepState();
      }
    } else if (notifyParent) {
      _emitStepState();
    }
  }

  void _onSavingChanged(bool saving) {
    if (_isSaving == saving) return;
    _isSaving = saving;
    _emitStepState();
  }

  List<String> _buildValidationErrors(AppLocalizations l10n) {
    final errors = <String>[];
    if (_currYearController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.currentAcademicYearLabel));
    }
    if (_selectedSchoolLevelGroupId.isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.targetCycleLabel));
    }
    if (_selectedSchoolLevelId.isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.targetLevelLabel));
    }
    return errors;
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

    _dispatchDraftTargetAcademic();
  }

  void _dispatchDraftTargetAcademic() {
    _awaitingDraftSave = true;
    _onSavingChanged(true);
    context.read<EnrollmentOfflineBloc>().add(
      SaveDraftTargetAcademicRequested(
        enrollmentId: widget.enrollmentId,
        schoolLevelId: _selectedSchoolLevelId,
        schoolLevelGroupId: _selectedSchoolLevelGroupId,
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

  void _applyBootstrapDefaults(AcademicYearContext academicYearContext) {
    bool bootstrapChanged = false;
    final previousCurrentYear = _currYearController.text;
    _currYearController.text = academicYearContext.academicYear.name;
    if (previousCurrentYear != _currYearController.text) {
      bootstrapChanged = true;
    }
    if (_bootstrapDefaultsApplied) return;

    final groupBundles = academicYearContext.schoolLevelGroups;
    final selectedGroupBundle = groupBundles
        .where((g) => g.group.id == _selectedSchoolLevelGroupId)
        .firstOrNull;

    if (selectedGroupBundle == null && groupBundles.isNotEmpty) {
      _selectedSchoolLevelGroupId = groupBundles.first.group.id;
      // Ne pas réinitialiser _initialSchoolLevelGroupId : le snapshot initial
      // représente l'état serveur. Pour newFirstRegistration, _initial* reste ''
      // → formulaire dirty après application des defaults bootstrap.
      bootstrapChanged = true;
    }

    final resolvedGroupBundle = groupBundles
        .where((g) => g.group.id == _selectedSchoolLevelGroupId)
        .firstOrNull;
    if (resolvedGroupBundle != null &&
        resolvedGroupBundle.levels.every(
          (l) => l.id != _selectedSchoolLevelId,
        )) {
      _selectedSchoolLevelId = resolvedGroupBundle.levels.isNotEmpty
          ? resolvedGroupBundle.levels.first.id
          : '';
      // Idem : ne pas écraser _initialSchoolLevelId.
      bootstrapChanged = true;
    }

    _bootstrapDefaultsApplied = true;

    if (bootstrapChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _recomputeFormState();
      });
    }
  }

  /// Calcule la classe cible depuis la classe de l'année précédente
  /// (réinscription), UNIQUEMENT si le dossier n'a ENCORE rien de persisté
  /// pour la classe cible ([_isPersistedTargetEmpty]) — sinon on conserve la
  /// valeur telle quelle, qu'elle vienne d'un choix manuel ou d'un
  /// enregistrement précédent. Ré-évalué à chaque build (idempotent, comme
  /// [_applyBootstrapDefaults]) tant que rien n'est encore persisté : si
  /// l'Antécédents est confirmé APRÈS l'ouverture de cette étape (donc après
  /// qu'un défaut naïf ait déjà été affiché), le calcul reprend la main dès
  /// que la donnée devient disponible — mais un choix manuel dans la même
  /// session ([_targetLevelManuallySet]) n'est lui jamais écrasé.
  ///
  /// Ne s'applique QUE si l'Antécédents a déjà été confirmé
  /// ([_hasConfirmedPreviousYearData]) : `validatedPreviousYear` vaut `false`
  /// par défaut tant que rien n'a été saisi, ce qui n'est PAS la même chose
  /// qu'un redoublement réel — pas de valeur inventée, on force la saisie.
  void _applyAutoTargetLevel(AcademicYearContext academicYearContext) {
    if (_targetLevelManuallySet) return;
    if (!_isPersistedTargetEmpty) return;
    if (!_hasConfirmedPreviousYearData) return;

    final previousLevelLabel = widget.enrollmentDetail.previousSchoolLevel;
    if (previousLevelLabel.trim().isEmpty) return;

    final resolution = resolveTargetSchoolLevel(
      schoolLevelGroups: academicYearContext.schoolLevelGroups,
      previousSchoolLevelLabel: previousLevelLabel,
      previousSchoolLevelGroupLabel:
          widget.enrollmentDetail.previousSchoolLevelGroup,
      validatedPreviousYear: widget.enrollmentDetail.validatedPreviousYear,
    );
    if (resolution == null) return;
    if (_selectedSchoolLevelGroupId == resolution.schoolLevelGroupId &&
        _selectedSchoolLevelId == resolution.schoolLevelId &&
        _targetLevelAutoFilled) {
      return;
    }

    _selectedSchoolLevelGroupId = resolution.schoolLevelGroupId;
    _selectedSchoolLevelId = resolution.schoolLevelId;
    _targetLevelAutoFilled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recomputeFormState();
    });
  }

  bool get _isTargetLevelAutoComputed => _targetLevelAutoFilled;

  /// `schoolLevelId`/`schoolLevelGroupId` du dossier PERSISTÉ (pas la
  /// sélection locale, potentiellement déjà défaultée naïvement par
  /// [_applyBootstrapDefaults]) — « target year vide » au sens où rien n'a
  /// encore été enregistré pour ce dossier.
  bool get _isPersistedTargetEmpty =>
      widget.enrollmentDetail.schoolLevelId.isEmpty &&
      widget.enrollmentDetail.schoolLevelGroupId.isEmpty;

  /// `previousRank` n'est renseigné qu'après un enregistrement réussi de
  /// l'étape Antécédents (moyenne + rang requis pour sauvegarder) — signal
  /// fiable que `validatedPreviousYear` reflète une vraie saisie et pas le
  /// défaut `false` d'un champ jamais rempli.
  bool get _hasConfirmedPreviousYearData =>
      widget.enrollmentDetail.previousRank != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showValidation = _showValidationHints || (_isDirty && !_isValid);

    return EnrollmentDraftStepSaveListener(
      enabled: true,
      isAwaiting: () => _awaitingDraftSave,
      onSaved: _onDraftSaved,
      onError: _onDraftError,
      child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        builder: (context, academicYearState) {
          final academicYearContext = academicYearState.context;
          if (academicYearContext != null) {
            // Le calcul auto doit avoir la main AVANT le défaut naïf de
            // _applyBootstrapDefaults (1er groupe/1er niveau) : sinon ce
            // dernier remplit _selectedXxx en premier et le calcul auto ne
            // voit plus jamais "target vide" au niveau de la sélection
            // locale (il se fie au dossier PERSISTÉ, pas à cette sélection).
            _applyAutoTargetLevel(academicYearContext);
            _applyBootstrapDefaults(academicYearContext);
          }

          return TargetAcademicInfoStepBody(
            bootstrap: academicYearContext,
            currYearController: _currYearController,
            targetOptionController: _targetOptionController,
            selectedSchoolLevelGroupId: _selectedSchoolLevelGroupId,
            selectedSchoolLevelId: _selectedSchoolLevelId,
            showValidation: showValidation,
            isLoading: _isSaving,
            canSave: _canSave,
            showInlineSaveButton: widget.showInlineSaveButton,
            onSave: _onSave,
            isEditable: widget.isEditable,
            isAutoComputed: _isTargetLevelAutoComputed,
            onGroupChanged: (groupId, firstLevelId) {
              setState(() {
                _selectedSchoolLevelGroupId = groupId;
                _selectedSchoolLevelId = firstLevelId;
                _targetLevelManuallySet = true;
                _targetLevelAutoFilled = false;
              });
              _recomputeFormState();
            },
            onLevelChanged: (levelId) {
              setState(() {
                _selectedSchoolLevelId = levelId;
                _targetLevelManuallySet = true;
                _targetLevelAutoFilled = false;
              });
              _recomputeFormState();
            },
            groupError: showValidation && _selectedSchoolLevelGroupId.isEmpty
                ? l10n.requiredFieldError(l10n.targetCycleLabel)
                : null,
            levelError: showValidation && _selectedSchoolLevelId.isEmpty
                ? l10n.requiredFieldError(l10n.targetLevelLabel)
                : null,
          );
        },
      ),
    );
  }
}
