import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_parent.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/widgets/enrollment_draft_step_save_listener.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_info_widgets.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/parent_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianInfoStep extends StatefulWidget {
  final List<ParentSummary> parentDetails;
  final String studentId;
  final String enrollmentId;

  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final VoidCallback? onRefreshRequested;
  final bool isEditable;

  /// Voir le commentaire sur `_onEmergencyContactChanged` : fourni, il ouvre la
  /// désignation du contact d'urgence sur un dossier en consultation et
  /// l'envoie par le chemin online.
  final ValueChanged<String?>? onEmergencyContactCommitted;
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
    this.onEmergencyContactCommitted,
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

  /// Vrai tant que la popin de conflit est ouverte. `_isBatchSaving` est déjà
  /// retombé à ce moment-là (l'écriture est bel et bien terminée, en échec) :
  /// sans ce second verrou, les gardes `if (_isBatchSaving) return` seraient
  /// inertes pendant toute la vie de la popin, et une seconde écriture
  /// déclenchée par ailleurs pourrait en empiler une deuxième.
  bool _isConflictDialogOpen = false;

  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;
  bool _isHydratingFromDetail = false;
  String? _expandedParentId;
  String? _primaryParentId;

  /// Tuteur désigné contact d'urgence, ou `null` si aucun. **Un seul id pour
  /// tout l'écran** : l'exclusivité tient à la forme de cet état, elle n'est
  /// pas une garde qu'on pourrait oublier d'écrire. Le serveur refuse en 422
  /// un agrégat qui en désignerait deux, et ce refus est TERMINAL — la saisie
  /// resterait bloquée dans la file d'écritures. Il ne doit donc jamais partir.
  String? _emergencyContactParentId;

  /// Quand il est fourni, la désignation du contact d'urgence reste **active
  /// même sur un dossier en consultation**, et part par ce chemin (online)
  /// plutôt que par le brouillon.
  ///
  /// C'est la seule brèche dans une page figée par construction, et elle est
  /// nommée : le reste du dossier finalisé n'est pas modifiable. Le contact
  /// d'urgence, lui, doit pouvoir changer sans rouvrir l'inscription — c'est
  /// l'information qu'on relira un jour d'accident.
  /// (déclaré sur le widget, cf. [GuardianInfoStep.onEmergencyContactCommitted])

  /// `true` dès que l'écran a touché à la désignation. Tant qu'il est faux,
  /// l'agrégat n'en dit RIEN (`null` sur chaque tuteur) plutôt que d'affirmer
  /// « personne » — le serveur lit l'absence comme « ne touche pas à ce qui
  /// est en place », et un dossier ouvert puis enregistré sans passer par
  /// cette case ne doit pas effacer une désignation venue d'ailleurs.
  bool _emergencyContactTouched = false;

  /// Désignation telle qu'elle était au chargement — l'ancre du « modifié ».
  String? _initialEmergencyContactParentId;

  /// Dernière désignation envoyée par le chemin online, gardée pour pouvoir la
  /// REJOUER : le `409` du serveur signale une course entre deux postes que le
  /// rejeu résout, et « Réessayer » doit renvoyer la même chose, pas la
  /// dernière valeur affichée entre-temps.
  String? _lastCommittedDesignation;

  /// Une écriture est en vol, OU l'utilisateur est en train d'arbitrer un
  /// conflit : dans les deux cas, la composition des tuteurs ne bouge pas.
  bool get _isBusy => _isBatchSaving || _isConflictDialogOpen;

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

        // La désignation vient du dossier, pas d'un défaut : contrairement au
        // tuteur principal, aucune carte n'est désignée d'office. Personne à
        // appeler est un état légitime — en inventer un serait pire que rien
        // le jour où il faudra vraiment appeler.
        final designated = _editableParentDetails
            .where((p) => p.emergencyContact)
            .map((p) => p.id)
            .toList(growable: false);
        _emergencyContactParentId = designated.length == 1
            ? designated.single
            : null;
        if (resetSnapshot) {
          _initialEmergencyContactParentId = _emergencyContactParentId;
          _emergencyContactTouched = false;
        }
      } else {
        _expandedParentId = null;
        _primaryParentId = null;
        _emergencyContactParentId = null;
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

    // La désignation du contact d'urgence compte dans le « modifié », au même
    // titre qu'un champ de carte : elle ne vit dans aucun `ParentItemValue`
    // (elle décrit le couple élève/tuteur, pas la fiche du tuteur), et sans
    // cette ligne, cocher la case laisserait le bouton d'enregistrement
    // inerte — la désignation ne partirait jamais.
    final dirtyNow =
        parentIds.any((id) => _itemStatesByParentId[id]?.dirty == true) ||
        _emergencyContactParentId != _initialEmergencyContactParentId;

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
      } else if (!ParentItemValue.isPhoneAcceptable(
        value.phoneNumber,
        initialPhone: parent.phoneNumber,
      )) {
        errors.add(
          'Gardien ${i + 1}: '
          '${l10n.phoneNumberInvalidError(PhoneCountry.congoDrc.nationalLength)}',
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

    if (!_isDirty || _isBusy) return;

    _dispatchDraftGuardians();
  }

  /// Écrit tous les tuteurs saisis dans le brouillon local (sémantique
  /// « remplace l'ensemble » — pas de create/update/unlink individuel).
  void _dispatchDraftGuardians() {
    // Ceinture : seul point de passage des trois chemins d'écriture (save,
    // rattachement, suppression). Un CTA futur qui rappellerait cette méthode
    // reste fermé sans avoir à y penser.
    if (!_canWrite(context)) return;
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
  /// `_linkFoundParent`/`_onRemoveGuardian`, qui sauvegardent immédiatement.
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
            // **Tri-état.** Tant que l'écran n'a pas touché à la désignation,
            // il n'en dit rien — `null`, pas `false` : le serveur lit
            // l'absence comme « ne touche à rien », et un `false` projeté
            // partout retirerait une désignation faite depuis un autre poste.
            // Une fois l'écran passé par là, il dit tout : `true` sur le
            // désigné, `false` sur les autres, ce qui rend le RETRAIT
            // exprimable.
            emergencyContact: _emergencyContactTouched
                ? parent.id == _emergencyContactParentId
                : null,
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
  ///
  /// Le refus n'est pas une impasse : la fiche qui porte déjà ce numéro est
  /// proposée au rattachement, et si elle est retenue elle REMPLACE la carte
  /// fautive. Le toast ne subsiste que là où aucune carte ne peut être
  /// désignée, ou là où le doublon est interne au dossier (deux cartes, même
  /// numéro) — cas où aucune fiche existante n'est en cause.
  Future<void> _onGuardianPhoneConflict(
    EnrollmentDraftGuardianPhoneConflict conflict,
  ) async {
    setState(() {
      _awaitingDraftSave = false;
      _isBatchSaving = false;
    });
    _onSavingChanged(false);

    final candidates = _cardsHoldingPhone(conflict.phoneNumber);
    if (candidates.length != 1) {
      AppSnackBar.showError(
        context,
        candidates.isEmpty
            ? conflict.message
            : AppLocalizations.of(context)!.guardianPhoneDuplicateInFormError,
      );
      return;
    }

    final conflictedParentId = candidates.single;
    setState(() => _isConflictDialogOpen = true);
    final LocalParent? found;
    try {
      found = await showGuardianPhoneConflictDialog(
        context: context,
        phoneNumber: conflict.phoneNumber,
        existingParentId: conflict.existingParentId,
      );
    } finally {
      if (mounted) setState(() => _isConflictDialogOpen = false);
    }
    if (!mounted) return;

    if (found == null) {
      // « Corriger le numéro » : rien n'a été écrit (l'enregistrement a
      // échoué), on ramène simplement la carte fautive sous les yeux.
      _onOpenParent(conflictedParentId);
      return;
    }

    _linkFoundParent(found, replacedParentId: conflictedParentId);
  }

  void _onAddGuardian() {
    if (!widget.isEditable || _isBusy) return;

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

  /// Ouvre la recherche d'une fiche existante POUR LA CARTE [targetParentId].
  ///
  /// L'appel part du bandeau posé dans la carte elle-même : la fiche retenue
  /// remplace donc ce tuteur-là, sans jamais s'ajouter à côté. C'est ce que
  /// l'utilisateur décrit quand il dit « en fait, c'est celui-ci » — l'ancien
  /// comportement (ajout en fin de liste) le laissait avec une ligne à moitié
  /// saisie à supprimer à la main.
  Future<void> _onLinkExistingParent(String targetParentId) async {
    if (!widget.isEditable || _isBusy) return;

    final found = await showParentSearchDialog(context: context);
    if (!mounted || found == null) return;

    _linkFoundParent(found, replacedParentId: targetParentId);
  }

  /// Substitue [found] à la carte [replacedParentId] : identité, téléphone et
  /// e-mail viennent de la fiche existante, l'id de la carte devient l'id RÉEL
  /// de cette fiche (ce qui marque le lien pour la garde d'unicité), et le
  /// brouillon est réécrit dans la foulée.
  void _linkFoundParent(LocalParent found, {required String replacedParentId}) {
    final index = _editableParentDetails.indexWhere(
      (parent) => parent.id == replacedParentId,
    );
    // La carte a disparu pendant que la popin était ouverte (ré-hydratation
    // du dossier). Ne rien faire EN SILENCE laisserait l'utilisateur devant
    // un choix validé qui n'a produit aucun effet.
    if (index < 0) {
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.guardianLinkTargetGoneError,
      );
      return;
    }

    final alreadyAdded = _editableParentDetails.any(
      (parent) => parent.id == found.id && parent.id != replacedParentId,
    );
    if (alreadyAdded) {
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.guardianSearchAlreadyAddedError,
      );
      return;
    }

    // Le lien de parenté appartient à CET élève, pas à la fiche parent (qui
    // peut être la mère d'un élève et la tante d'un autre) : ce que
    // l'utilisateur avait déjà choisi sur la carte survit au remplacement.
    final keptRelationshipType =
        _currentValuesByParentId[replacedParentId]?.relationshipType ??
        RelationshipType.guardian;

    final parentSummary = ParentSummary(
      id: found.id, // id RÉEL (existant) ⇒ marque le lien explicite
      firstName: found.firstName,
      lastName: found.lastName,
      surname: found.surname,
      identificationNumber: found.identificationNumber ?? '',
      phoneNumber: found.phoneNumber,
      email: found.email ?? '',
      relationshipType: keptRelationshipType,
    );

    setState(() {
      final next = List<ParentSummary>.from(_editableParentDetails);
      next[index] = parentSummary;
      _editableParentDetails = List<ParentSummary>.unmodifiable(next);

      // Retrait AVANT ajout : la carte peut déjà porter cet id (on rejoue la
      // même fiche), auquel cas l'ordre inverse effacerait ce qu'on vient
      // d'écrire.
      _currentValuesByParentId.remove(replacedParentId);
      _initialValuesByParentId.remove(replacedParentId);
      _itemStatesByParentId.remove(replacedParentId);
      _linkedFromSearchParentIds.remove(replacedParentId);

      final linkedValue = ParentItemValue.fromParent(parentSummary);
      _currentValuesByParentId[parentSummary.id] = linkedValue;
      _initialValuesByParentId[parentSummary.id] = linkedValue;
      _itemStatesByParentId[parentSummary.id] = ParentItemFormState(
        valid: linkedValue.isValid,
        dirty: false,
        changedFields: const <String, bool>{},
      );
      _linkedFromSearchParentIds.add(parentSummary.id);

      if (_expandedParentId == replacedParentId || _expandedParentId == null) {
        _expandedParentId = parentSummary.id;
      }
      if (_primaryParentId == replacedParentId || _primaryParentId == null) {
        _primaryParentId = parentSummary.id;
      }
    });

    _recomputeFormState();
    // Rattachement structurel (comme la suppression) : sauvegarde immédiate,
    // sans attendre un clic « Enregistrer » qui resterait grisé (le tuteur
    // rattaché est déjà valide mais pas "dirty" au sens d'une édition de
    // champ).
    _dispatchDraftGuardians();
  }

  /// Ids des cartes dont le numéro saisi est CELUI-CI, à la mise en forme
  /// près.
  List<String> _cardsHoldingPhone(String phoneNumber) {
    return _editableParentDetails
        .map((parent) => parent.id)
        .where(
          (id) => PhoneNumberFormat.sameNumber(
            _currentValuesByParentId[id]?.phoneNumber ?? '',
            phoneNumber,
          ),
        )
        .toList(growable: false);
  }

  void _onRemoveGuardian(String parentId) {
    if (!widget.isEditable || _isBusy) return;

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

      // Retirer le tuteur désigné retire la désignation : sinon l'écran
      // garderait un id qui ne correspond plus à aucune carte, et l'agrégat
      // partirait sans désigner personne tout en croyant l'avoir fait.
      if (_emergencyContactParentId == parentId) {
        _emergencyContactParentId = null;
        _emergencyContactTouched = true;
      }

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
    if (!widget.isEditable || _isBusy) return;

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
    // Sans cette garde, un id périmé (carte disparue pendant une popin)
    // replierait TOUTES les cartes sans en rouvrir aucune.
    if (!_editableParentDetails.any((parent) => parent.id == parentId)) return;
    setState(() => _expandedParentId = parentId);
  }

  void _onPrimaryParentChanged(String parentId) {
    if (_primaryParentId == parentId) return;
    setState(() => _primaryParentId = parentId);
    _recomputeFormState();
  }

  /// Désigne le tuteur à appeler en urgence, ou n'en désigne aucun
  /// ([parentId] à `null`).
  ///
  /// **Aucune garde d'unicité à écrire** : l'état est un id unique, désigner
  /// B remplace A dans le même geste. C'est ce qui rend impossible l'agrégat à
  /// deux désignations, refusé en 422 par le serveur — un refus TERMINAL qui
  /// bloquerait l'inscription dans la file d'écritures.
  void _onEmergencyContactChanged(String? parentId) {
    // Le chemin online s'ouvre AUSSI sur un dossier en consultation : c'est
    // toute sa raison d'être. Il ne touche pas au brouillon — le dossier est
    // finalisé, il n'y en a plus.
    final committer = widget.onEmergencyContactCommitted;
    if (committer != null) {
      // Le « Réessayer » du bandeau d'erreur rappelle ce chemin, et un
      // bandeau survit au changement d'écran : sans cette garde, un appui
      // après avoir quitté le dossier toucherait un élément mort.
      if (!mounted) return;
      if (_emergencyContactParentId == parentId) return;
      setState(() {
        _emergencyContactParentId = parentId;
        _emergencyContactTouched = true;
      });
      _lastCommittedDesignation = parentId;
      committer(parentId);
      return;
    }
    if (!widget.isEditable || _isBusy) return;
    if (_emergencyContactParentId == parentId && _emergencyContactTouched) {
      return;
    }
    setState(() {
      _emergencyContactParentId = parentId;
      _emergencyContactTouched = true;
    });
    _recomputeFormState();
  }

  /// Vrai si la session peut écrire ce dossier. Les CTA « Ajouter » /
  /// « Rechercher un parent » et la corbeille écrivent le brouillon SANS
  /// attendre le bouton « Enregistrer » du pied — lequel est, lui, gardé. Sans
  /// cette composition, un profil en lecture voyait « Enregistrer » masqué mais
  /// mutait quand même la composition des tuteurs ; la mutation partait ensuite
  /// dans l'agrégat finalisé par quelqu'un d'autre, donc acceptée par le
  /// serveur et attribuée au mauvais auteur.
  bool _canWrite(BuildContext context) => PermissionGate.allows(
    context,
    kEnrollmentSubmitAccess.requires,
    requiresAll: kEnrollmentSubmitAccess.requiresAll,
  );

  /// Rend compte de la désignation partie en ligne.
  ///
  /// **Un seul refus mérite « Réessayer » : le `409`.** Il vient d'une course
  /// entre deux postes que l'index unique du serveur vient de trancher, et le
  /// rejeu converge. Proposer le même bouton sur un `404` ou un `422` serait
  /// inviter à reproduire exactement ce que le serveur refuse.
  void _onEmergencyContactStateChanged(
    BuildContext context,
    ParentState state,
  ) {
    if (state.operation != ParentOperation.emergencyContact) return;
    final l10n = AppLocalizations.of(context)!;

    if (state.status == ParentUpdateStatus.success) {
      AppSnackBar.showSuccess(
        context,
        _lastCommittedDesignation == null
            ? l10n.guardianEmergencyContactCleared
            : l10n.guardianEmergencyContactSaved,
      );
      widget.onRefreshRequested?.call();
      return;
    }
    if (state.status != ParentUpdateStatus.failure) return;

    // L'écran a affiché la désignation avant l'acquittement : l'échec doit la
    // reprendre, sinon la case resterait cochée sur un serveur qui a refusé.
    setState(() {
      _emergencyContactParentId = _initialEmergencyContactParentId;
      _emergencyContactTouched = false;
    });
    AppSnackBar.showError(
      context,
      state.errorMessage ?? l10n.guardianEmergencyContactFailed,
      onRetry: state.retryable
          ? () => _onEmergencyContactChanged(_lastCommittedDesignation)
          : null,
      retryLabel: state.retryable ? l10n.guardianEmergencyContactRetry : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return EnrollmentDraftStepSaveListener(
      enabled: true,
      isAwaiting: () => _awaitingDraftSave,
      onSaved: _onDraftSaved,
      onError: _onDraftError,
      onGuardianPhoneConflict: _onGuardianPhoneConflict,
      child: widget.onEmergencyContactCommitted == null
          ? _rebuiltOnPermissionChange(_buildBody)
          : BlocListener<ParentBloc, ParentState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.operation != current.operation,
              listener: _onEmergencyContactStateChanged,
              child: _rebuiltOnPermissionChange(_buildBody),
            ),
    );
  }

  /// Rejoue [builder] quand l'ensemble des droits change.
  ///
  /// `_canWrite` est une lecture ponctuelle — [PermissionGate.allows] ne
  /// s'abonne à rien. Lue dans `build`, elle est donc juste à chaque
  /// reconstruction… mais rien ne reconstruisait cette étape sur une émission
  /// de l'`AuthBloc` : un droit accordé ou retiré par un refresh en arrière-plan
  /// laissait les champs et la corbeille dans l'état du montage.
  ///
  /// Transparent sans `AuthBloc` dans l'arbre — même convention que le gate.
  Widget _rebuiltOnPermissionChange(WidgetBuilder builder) {
    final authBloc = PermissionGate.maybeBlocOf(context);
    if (authBloc == null) return builder(context);

    return BlocBuilder<AuthBloc, AuthState>(
      bloc: authBloc,
      buildWhen: (prev, curr) =>
          !listEquals(prev.permissions, curr.permissions),
      builder: (context, _) => builder(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return GuardianInfoStepBody(
      parentDetails: _editableParentDetails,
      onItemStateChanged: _onParentItemStateChanged,
      onItemValueChanged: _onParentItemValueChanged,
      onAddParent: _onAddGuardian,
      onLinkExistingParent: _onLinkExistingParent,
      onRemoveParent: _onRemoveGuardianRequested,
      onOpenParent: _onOpenParent,
      onPrimaryParentChanged: _onPrimaryParentChanged,
      expandedParentId: _expandedParentId,
      primaryParentId: _primaryParentId,
      emergencyContactParentId: _emergencyContactParentId,
      onEmergencyContactChanged:
          widget.isEditable || widget.onEmergencyContactCommitted != null
          ? _onEmergencyContactChanged
          : null,
      isLoading: _isBatchSaving,
      canSave: _canSave,
      showInlineSaveButton: widget.showInlineSaveButton,
      onSave: _onSave,
      isEditable: widget.isEditable && _canWrite(context),
      identityLockedParentIds: _linkedFromSearchParentIds,
    );
  }
}
