import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/widgets/enrollment_draft_step_save_listener.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_info_widgets.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianInfoStep extends StatefulWidget {
  final List<ParentSummary> parentDetails;
  final String studentId;
  final String enrollmentId;

  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final VoidCallback? onRefreshRequested;
  final bool isEditable;
  final EnrollmentStepSubmitController? stepController;

  const GuardianInfoStep({
    super.key,
    required this.parentDetails,
    required this.studentId,
    required this.enrollmentId,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
    this.onRefreshRequested,
    this.isEditable = true,
    this.stepController,
  });

  @override
  State<GuardianInfoStep> createState() => GuardianInfoStepState();
}

class GuardianInfoStepState extends State<GuardianInfoStep> {
  late List<ParentSummary> _editableParentDetails;
  late Map<String, ParentItemValue> _currentValuesByParentId;
  late Map<String, ParentItemValue> _initialValuesByParentId;
  late Map<String, ParentItemFormState> _itemStatesByParentId;

  /// Ids des tuteurs rattachés via "Rechercher un parent" cette session (id
  /// RÉEL d'une fiche existante) — pilote le verrouillage identité (UI) et
  /// `ConfirmParentDraft.isLinkedToExisting` (garde d'unicité téléphone).
  final Set<String> _linkedFromSearchParentIds = <String>{};

  bool _isBatchSaving = false;
  bool _awaitingDraftSave = false;

  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;
  bool _isHydratingFromDetail = false;
  String? _expandedParentId;
  String? _primaryParentId;

  bool get _canSave => _stepState.canSave;
  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

  String _normalizeEmailForApi(String rawEmail) {
    return rawEmail.trim().toLowerCase();
  }

  void submitForm() => _onSave();

  @override
  void initState() {
    super.initState();
    _syncFromParentDetails(widget.parentDetails, resetSnapshot: true);

    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });

    widget.stepController?.bind(submitForm);
  }

  ParentSummary _buildDraftParent() {
    // Id RÉEL et STABLE (pas un timestamp) : reste identique à travers les
    // re-sauvegardes de cette ligne UI, condition requise par la garde
    // d'unicité téléphone (sinon un ré-envoi se comparerait à lui-même sous
    // un id différent → faux conflit).
    final draftId = getIt<IdGenerator>().newId();
    return ParentSummary(
      id: draftId,
      firstName: '',
      lastName: '',
      surname: null,
      identificationNumber: '',
      phoneNumber: '',
      email: '',
      relationshipType: RelationshipType.guardian,
    );
  }

  void _syncFromParentDetails(
    List<ParentSummary> parents, {
    required bool resetSnapshot,
  }) {
    _isHydratingFromDetail = true;
    try {
      final effectiveParents = parents.isEmpty
          ? [_buildDraftParent()]
          : List<ParentSummary>.from(parents);
      _editableParentDetails = effectiveParents;
      _currentValuesByParentId = <String, ParentItemValue>{
        for (final parent in _editableParentDetails)
          parent.id: ParentItemValue.fromParent(parent),
      };

      _itemStatesByParentId = <String, ParentItemFormState>{
        for (final parent in _editableParentDetails)
          parent.id: ParentItemFormState(
            valid: ParentItemValue.fromParent(parent).isValid,
            dirty: false,
            changedFields: const <String, bool>{},
          ),
      };

      if (resetSnapshot) {
        _initialValuesByParentId = <String, ParentItemValue>{
          for (final parent in _editableParentDetails)
            parent.id: ParentItemValue.fromParent(parent),
        };
      }

      if (_editableParentDetails.isNotEmpty) {
        final expandedStillExists =
            _expandedParentId != null &&
            _editableParentDetails.any((p) => p.id == _expandedParentId);
        _expandedParentId = expandedStillExists
            ? _expandedParentId
            : _editableParentDetails.first.id;

        final primaryStillExists =
            _primaryParentId != null &&
            _editableParentDetails.any((p) => p.id == _primaryParentId);
        _primaryParentId = primaryStillExists
            ? _primaryParentId
            : _editableParentDetails.first.id;
      } else {
        _expandedParentId = null;
        _primaryParentId = null;
      }
    } finally {
      _isHydratingFromDetail = false;
    }
  }

  @override
  void didUpdateWidget(covariant GuardianInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stepController != widget.stepController) {
      oldWidget.stepController?.unbind(submitForm);
      widget.stepController?.bind(submitForm);
    }

    if (oldWidget.parentDetails != widget.parentDetails) {
      _syncFromParentDetails(widget.parentDetails, resetSnapshot: true);
      _isBatchSaving = false;
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
    super.dispose();
  }

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

  void _recomputeFormState({bool notifyParent = true}) {
    if (_isHydratingFromDetail) return;

    // Défensif: éviter setState pendant la phase de build.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _recomputeFormState(notifyParent: notifyParent);
      });
      return;
    }

    final parentIds = _editableParentDetails
        .map((p) => p.id)
        .toList(growable: false);

    final validNow =
        parentIds.isNotEmpty &&
        _primaryParentId != null &&
        parentIds.contains(_primaryParentId) &&
        parentIds.every((id) => _itemStatesByParentId[id]?.valid == true);

    final dirtyNow = parentIds.any(
      (id) => _itemStatesByParentId[id]?.dirty == true,
    );

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

  void _onParentItemStateChanged(String parentId, ParentItemFormState state) {
    _itemStatesByParentId[parentId] = state;
    _recomputeFormState();
  }

  void _onParentItemValueChanged(String parentId, ParentItemValue value) {
    _currentValuesByParentId[parentId] = value;
    _recomputeFormState();
  }

  List<String> _buildValidationErrors(AppLocalizations l10n) {
    final errors = <String>[];

    if (_editableParentDetails.isEmpty) {
      errors.add(l10n.requiredFieldError('Gardien'));
      return errors;
    }

    for (var i = 0; i < _editableParentDetails.length; i++) {
      final parent = _editableParentDetails[i];
      final value = _currentValuesByParentId[parent.id];
      if (value == null) continue;

      if (value.firstName.trim().isEmpty) {
        errors.add(
          'Gardien ${i + 1}: ${l10n.requiredFieldError(l10n.firstName)}',
        );
      }
      if (value.lastName.trim().isEmpty) {
        errors.add(
          'Gardien ${i + 1}: ${l10n.requiredFieldError(l10n.lastName)}',
        );
      }
      if (value.phoneNumber.trim().isEmpty) {
        errors.add(
          'Gardien ${i + 1}: ${l10n.requiredFieldError(l10n.phoneNumberLabel)}',
        );
      }
      if (value.email.trim().isNotEmpty &&
          !ParentItemValue.isEmailValid(value.email)) {
        errors.add('Gardien ${i + 1}: ${l10n.pleaseEnterValidEmail}');
      }
    }

    if (_primaryParentId == null ||
        !_editableParentDetails.any(
          (parent) => parent.id == _primaryParentId,
        )) {
      errors.add(l10n.guardianPrimaryRequiredHint);
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

    if (!_isDirty || _isBatchSaving) return;

    _dispatchDraftGuardians();
  }

  /// Écrit tous les tuteurs saisis dans le brouillon local (sémantique
  /// « remplace l'ensemble » — pas de create/update/unlink individuel).
  void _dispatchDraftGuardians() {
    final studentId = widget.studentId.trim();
    if (studentId.isEmpty) {
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.validatePersonalInfoHint,
      );
      return;
    }

    setState(() {
      _awaitingDraftSave = true;
      _isBatchSaving = true;
    });
    _onSavingChanged(true);
    context.read<EnrollmentOfflineBloc>().add(
      SaveDraftGuardiansRequested(
        studentId: studentId,
        parents: _buildConfirmParentDrafts(),
      ),
    );
  }

  /// Exclut les tuteurs incomplets (ex. la ligne vide auto-créée à l'ouverture
  /// d'un wizard sans tuteur, jamais remplie) des écritures déclenchées SANS
  /// passer par la garde `_isValid` de `_onSave()` — c'est le cas de
  /// `_onSearchParent`/`_onRemoveGuardian`, qui sauvegardent immédiatement.
  /// Sans ce filtre, une ligne vide (`phoneNumber: ''`) atteindrait la garde
  /// d'unicité téléphone et soit polluerait `parents` d'une fiche vide, soit
  /// ferait échouer un rattachement légitime avec un conflit incompréhensible
  /// dès qu'une 2ᵉ ligne vide existe ailleurs en base.
  List<ConfirmParentDraft> _buildConfirmParentDrafts() {
    return _editableParentDetails
        .map((parent) {
          final value = _currentValuesByParentId[parent.id];
          if (value == null || !value.isValid) return null;
          return ConfirmParentDraft(
            id: parent.id,
            isLinkedToExisting: _linkedFromSearchParentIds.contains(parent.id),
            firstName: value.firstName.trim(),
            lastName: value.lastName.trim(),
            surname: value.surname.trim().isEmpty ? null : value.surname.trim(),
            phoneNumber: value.phoneNumber.trim(),
            email: value.email.trim().isEmpty
                ? null
                : _normalizeEmailForApi(value.email),
            relationshipType: value.relationshipType.name.toUpperCase(),
          );
        })
        .whereType<ConfirmParentDraft>()
        .toList(growable: false);
  }

  void _onDraftSaved() {
    setState(() {
      _awaitingDraftSave = false;
      _isBatchSaving = false;
      if (_showValidationHints) _showValidationHints = false;
    });
    _onSavingChanged(false);
    AppSnackBar.showSuccess(
      context,
      AppLocalizations.of(context)!.academicInfoSaveSuccess,
    );
    widget.onRefreshRequested?.call();
  }

  // NB : les mutations de _isBatchSaving/_awaitingDraftSave DOIVENT passer par
  // setState() ici — sans ça, GuardianInfoStepState.build() n'est jamais
  // ré-invoqué après une erreur (contrairement au chemin succès ci-dessus, qui
  // se "raccroche" au setState() déjà programmé par le flux qui a déclenché la
  // sauvegarde) : l'AbsorbPointer + le spinner de GuardianInfoStepBody restent
  // figés indéfiniment alors que la sauvegarde est en réalité terminée.
  void _onDraftError(String message) {
    setState(() {
      _awaitingDraftSave = false;
      _isBatchSaving = false;
    });
    _onSavingChanged(false);
  }

  /// Doublon de téléphone (garde d'unicité de l'étape Tuteurs) : seul cas où
  /// cette étape affiche elle-même le message d'erreur — `_onDraftError`
  /// reste muet pour les échecs génériques (déjà couverts par le toast
  /// générique de `EnrollmentStepperScope`, en amont).
  void _onGuardianPhoneConflict(String message) {
    setState(() {
      _awaitingDraftSave = false;
      _isBatchSaving = false;
    });
    _onSavingChanged(false);
    AppSnackBar.showError(context, message);
  }

  void _onAddGuardian() {
    if (!widget.isEditable || _isBatchSaving) return;

    final draftId = getIt<IdGenerator>().newId();
    final draftParent = ParentSummary(
      id: draftId,
      firstName: '',
      lastName: '',
      surname: null,
      identificationNumber: '',
      phoneNumber: '',
      email: '',
      relationshipType: RelationshipType.guardian,
    );

    setState(() {
      _editableParentDetails = <ParentSummary>[
        ..._editableParentDetails,
        draftParent,
      ];
      _currentValuesByParentId[draftId] = ParentItemValue.fromParent(
        draftParent,
      );
      _initialValuesByParentId[draftId] = ParentItemValue.fromParent(
        draftParent,
      );
      _itemStatesByParentId[draftId] = ParentItemFormState(
        valid: ParentItemValue.fromParent(draftParent).isValid,
        dirty: false,
        changedFields: const <String, bool>{},
      );
      _expandedParentId = draftId;
      _primaryParentId ??= draftId;
    });

    _recomputeFormState();
  }

  Future<void> _onSearchParent() async {
    if (!widget.isEditable || _isBatchSaving) return;

    final found = await showParentSearchDialog(context: context);
    if (!mounted || found == null) return;

    final alreadyAdded = _editableParentDetails.any(
      (parent) => parent.id == found.id,
    );
    if (alreadyAdded) {
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.guardianSearchAlreadyAddedError,
      );
      return;
    }

    final parentSummary = ParentSummary(
      id: found.id, // id RÉEL (existant) ⇒ marque le lien explicite
      firstName: found.firstName,
      lastName: found.lastName,
      surname: found.surname,
      identificationNumber: found.identificationNumber ?? '',
      phoneNumber: found.phoneNumber,
      email: found.email ?? '',
      relationshipType: RelationshipType.guardian,
    );

    setState(() {
      _editableParentDetails = <ParentSummary>[
        ..._editableParentDetails,
        parentSummary,
      ];
      _currentValuesByParentId[parentSummary.id] = ParentItemValue.fromParent(
        parentSummary,
      );
      _initialValuesByParentId[parentSummary.id] = ParentItemValue.fromParent(
        parentSummary,
      );
      _itemStatesByParentId[parentSummary.id] = ParentItemFormState(
        valid: ParentItemValue.fromParent(parentSummary).isValid,
        dirty: false,
        changedFields: const <String, bool>{},
      );
      _linkedFromSearchParentIds.add(parentSummary.id);
      _expandedParentId = parentSummary.id;
      _primaryParentId ??= parentSummary.id;
    });

    _recomputeFormState();
    // Rattachement structurel (comme la suppression) : sauvegarde immédiate,
    // sans attendre un clic « Enregistrer » qui resterait grisé (le nouveau
    // tuteur est déjà valide mais pas "dirty" au sens d'une édition de champ).
    _dispatchDraftGuardians();
  }

  void _onRemoveGuardian(String parentId) {
    if (!widget.isEditable || _isBatchSaving) return;

    final exists = _editableParentDetails.any(
      (parent) => parent.id == parentId,
    );
    if (!exists) return;

    setState(() {
      _editableParentDetails = _editableParentDetails
          .where((parent) => parent.id != parentId)
          .toList(growable: false);
      _currentValuesByParentId.remove(parentId);
      _initialValuesByParentId.remove(parentId);
      _itemStatesByParentId.remove(parentId);
      _linkedFromSearchParentIds.remove(parentId);

      if (_expandedParentId == parentId) {
        _expandedParentId = _editableParentDetails.isNotEmpty
            ? _editableParentDetails.first.id
            : null;
      }

      if (_primaryParentId == parentId) {
        _primaryParentId = _editableParentDetails.isNotEmpty
            ? _editableParentDetails.first.id
            : null;
      }
    });

    _recomputeFormState();
  }

  Future<void> _onRemoveGuardianRequested(String parentId) async {
    if (!widget.isEditable || _isBatchSaving) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: l10n.guardianDeleteConfirmTitle,
      message: l10n.guardianDeleteConfirmMessage,
      confirmLabel: l10n.guardianDeleteConfirmAction,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );

    if (!mounted || !confirmed) return;

    // Offline-first : suppression locale puis ré-écriture de l'ensemble des
    // tuteurs dans le brouillon (jamais d'appel d'unlink serveur).
    _onRemoveGuardian(parentId);
    if (_editableParentDetails.isNotEmpty) {
      _dispatchDraftGuardians();
    }
  }

  void _onOpenParent(String parentId) {
    if (_expandedParentId == parentId) return;
    setState(() => _expandedParentId = parentId);
  }

  void _onPrimaryParentChanged(String parentId) {
    if (_primaryParentId == parentId) return;
    setState(() => _primaryParentId = parentId);
    _recomputeFormState();
  }

  @override
  Widget build(BuildContext context) {
    return EnrollmentDraftStepSaveListener(
      enabled: true,
      isAwaiting: () => _awaitingDraftSave,
      onSaved: _onDraftSaved,
      onError: _onDraftError,
      onGuardianPhoneConflict: _onGuardianPhoneConflict,
      child: GuardianInfoStepBody(
        parentDetails: _editableParentDetails,
        onItemStateChanged: _onParentItemStateChanged,
        onItemValueChanged: _onParentItemValueChanged,
        onAddParent: _onAddGuardian,
        onSearchParent: _onSearchParent,
        onRemoveParent: _onRemoveGuardianRequested,
        onOpenParent: _onOpenParent,
        onPrimaryParentChanged: _onPrimaryParentChanged,
        expandedParentId: _expandedParentId,
        primaryParentId: _primaryParentId,
        isLoading: _isBatchSaving,
        canSave: _canSave,
        showInlineSaveButton: widget.showInlineSaveButton,
        onSave: _onSave,
        isEditable: widget.isEditable,
        identityLockedParentIds: _linkedFromSearchParentIds,
      ),
    );
  }
}
