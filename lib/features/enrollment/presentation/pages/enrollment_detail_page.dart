import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_previous_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/local_enrollment_detail_mapper.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/local_enrollment_summary_mapper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_content_shell.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_journey_scaffold.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_state_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_navigation_helper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

class EnrollmentDetailPage extends StatefulWidget {
  final EnrollmentDetailIntent intent;

  const EnrollmentDetailPage({super.key, required this.intent});

  @override
  State<EnrollmentDetailPage> createState() => _EnrollmentDetailPageState();
}

class _EnrollmentDetailPageState extends State<EnrollmentDetailPage> {
  late EnrollmentDetailPolicy _policy;
  late EnrollmentDetailIntent _effectiveIntent;
  int _currentStep = 0;

  // Parcours brouillon offline-first : ids client figés + dernier détail lu en
  // base locale, conservés à travers les états transitoires du brouillon.
  DraftIds? _draftIds;
  LocalEnrollmentDetail? _draftLocal;

  // Seed déjà dispatché pour cet intent (RE/PRE/reprise) : le dossier serveur
  // n'est photographié qu'une fois par entrée dans le wizard.
  EnrollmentDetailIntent? _seededIntent;

  // Dossier LOCAL non synchronisé ouvert depuis le listing (read-your-writes) :
  // affiché en LECTURE SEULE (déjà finalisé/en file de synchro). Détecté via une
  // lecture locale par enrollmentId ; null pour un dossier serveur.
  LocalEnrollmentDetail? _localReadOnly;

  /// Force la bascule LECTURE SEULE au prochain détail local chargé, quel que
  /// soit l'axe synchro. Posé par la **sonde au tap RE** quand elle trouve un
  /// dossier FINALISÉ (option b : éditable ⟺ DRAFT) — le chargement local qui
  /// suit doit être rendu en lecture seule même s'il est SYNCED (là où
  /// [isUnsyncedLocalWrite] seul laisserait passer).
  bool _forceLocalReadOnly = false;

  /// Origine « première inscription » (listing) : seule à pouvoir pointer un
  /// dossier LOCAL (les items de superposition read-your-writes). RE/PRE/NEW
  /// ne sont jamais dans le cache local `enrollments` par leur enrollmentId.
  bool get _isFirstRegistrationListing =>
      _effectiveIntent.origin == EnrollmentDetailOrigin.firstRegistration;

  // Mémoïsation de l'agrégat local : EnrollmentDetail n'est pas Equatable, donc
  // recréer une instance à chaque build resynchroniserait le stepper (perte de
  // l'étape/dirty). On ne recompose que si une entrée (identité) a changé.
  EnrollmentDetail? _cachedAggregate;
  LocalEnrollmentDetail? _cachedLocal;
  DraftIds? _cachedIds;
  AcademicYearContext? _cachedAcademicYearContext;

  bool get _isNewOffline =>
      _effectiveIntent.origin == EnrollmentDetailOrigin.newFirstRegistration;

  @override
  void initState() {
    super.initState();
    _policy = EnrollmentDetailPolicyResolver.fromIntent(widget.intent);
    _effectiveIntent = widget.intent;
    _requestBootstrapContexts();
    _initializeJourney();
  }

  @override
  void didUpdateWidget(covariant EnrollmentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intent != widget.intent) {
      final shouldRefreshFromRouter = widget.intent != _effectiveIntent;
      _policy = EnrollmentDetailPolicyResolver.fromIntent(widget.intent);
      _effectiveIntent = widget.intent;
      _currentStep = 0;
      if (shouldRefreshFromRouter) {
        _requestBootstrapContexts();
        _initializeJourney();
      }
    }
  }

  /// Amorce du parcours : brouillon vierge (NEW), ou chargement serveur —
  /// prélude au seed du brouillon (RE/PRE/reprise) ou simple consultation.
  void _initializeJourney() {
    _draftIds = null;
    _draftLocal = null;
    _seededIntent = null;
    _localReadOnly = null;
    _forceLocalReadOnly = false;
    _draftFormShown = false;
    if (_isNewOffline) {
      context.read<EnrollmentOfflineBloc>().add(const StartDraftRequested());
      return;
    }
    // Reprise d'un brouillon LOCAL (DRAFT) déjà en base : charge l'agrégat par
    // id (aucun seed, aucun GET serveur voué à 404) → le stepper l'édite par
    // étape comme un NEW, jusqu'à la finalisation.
    if (_effectiveIntent.origin == EnrollmentDetailOrigin.localDraftResume) {
      context.read<EnrollmentOfflineBloc>().add(
        LoadDraftDetailRequested(_effectiveIntent.enrollmentId),
      );
      return;
    }
    // Première inscription (listing 100 % local) : le détail est servi en
    // LECTURE SEULE depuis l'agrégat local hydraté par le pull snapshot — plus
    // AUCUN GET serveur. La lecture locale bascule la page en consultation
    // (`_buildLocalReadOnly`) quel que soit l'axe synchro (voir _onLocalDetail).
    // L'édition d'un dossier déjà synchronisé n'est pas supportée par le modèle
    // d'écriture (`seedDraft` rejette les lignes non-DRAFT) ; les brouillons
    // DRAFT éditables sont, eux, routés en amont vers `localDraftResume` par le
    // scaffold et n'atteignent jamais cette origine.
    if (_isFirstRegistrationListing) {
      context.read<EnrollmentOfflineBloc>().add(
        LoadLocalEnrollmentDetail(_effectiveIntent.enrollmentId),
      );
      return;
    }
    _requestDetail();
  }

  // Dossier trouvé en local → bascule en lecture seule. Trois déclencheurs :
  //  - **Première inscription** (`_isFirstRegistrationListing`) : consultation
  //    LECTURE SEULE systématique, QUEL QUE SOIT l'axe synchro. Le listing est
  //    100 % local et l'agrégat est hydraté (SYNCED) par le pull snapshot ; on
  //    n'éditera jamais un dossier déjà synchronisé (le modèle d'écriture le
  //    refuse — `seedDraft` rejette les lignes non-DRAFT). Les brouillons DRAFT
  //    éditables sont routés en amont vers `localDraftResume` (jamais ici).
  //  - une écriture locale **non synchronisée** (PENDING_SYNC / SYNC_ERROR) de
  //    la superposition read-your-writes (RE/PRE) : id absent du serveur (404).
  //  - la **sonde au tap RE** ayant trouvé un dossier finalisé
  //    (`_forceLocalReadOnly`).
  void _onLocalDetail(BuildContext context, EnrollmentOfflineState state) {
    // Dossier LOCAL trouvé → bascule en consultation lecture seule.
    if (state is EnrollmentOfflineDetailLoaded &&
        (_forceLocalReadOnly ||
            _isFirstRegistrationListing ||
            isUnsyncedLocalWrite(state.detail.enrollment.syncState))) {
      setState(() => _localReadOnly = state.detail);
    }
  }

  void _requestDetail() {
    _policy.requestLoad(context.read<EnrollmentBloc>(), _effectiveIntent);
  }

  void _requestBootstrapContexts() {
    if (_policy.requiresCurrentYearBootstrap(_effectiveIntent)) {
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    }

    if (_policy.requiresPreviousYearBootstrap(_effectiveIntent)) {
      context.read<AcademicYearPreviousContextBloc>().add(
        const AcademicYearPreviousContextRequested(),
      );
    }
  }

  // Conserve les ids client (au démarrage/seed) puis le détail local (après
  // chaque écriture d'étape) pour reconstruire l'agrégat sans GET serveur.
  void _onDraftAggregateState(
    BuildContext context,
    EnrollmentOfflineState state,
  ) {
    if (state is EnrollmentDraftStarted) {
      setState(
        () => _draftIds = DraftIds(
          enrollmentId: state.enrollmentId,
          studentId: state.studentId,
        ),
      );
    } else if (state is EnrollmentDraftDetailLoaded) {
      setState(() => _draftLocal = state.detail);
    }
  }

  // Seed RE/PRE **depuis le local** : dès que l'année courante (bootstrap) est
  // disponible, dispatche l'événement de seed offline (une seule fois par
  // entrée). RE lit la cohorte N-1 par studentId ; PRE lit la préinscription par
  // id. Cohorte/snapshot non peuplés (pull dormant) → l'événement échoue et le
  // wizard reste vide (régression assumée, décision utilisateur).
  void _maybeSeedFromLocalRef(AcademicYearContext? academicYearContext) {
    if (!mounted || !_policy.seedsFromLocalRef) return;
    if (_seededIntent == _effectiveIntent) return;
    // Gel READ_ONLY (ADR-010) : le seed CRÉE des lignes brouillon en base
    // locale — un tap « pour voir » sur un candidat RE en session lecture
    // seule laisserait des dossiers DRAFT fantômes. On ne seed pas ; la page
    // retombe sur son état vide/erreur, et le bouton Réessayer du seed est
    // lui aussi neutralisé par ce même garde au rejeu.
    if (SessionWriteGate.blocksWritesOf(context)) return;
    // Même raison, autre cause : le seed est le premier geste d'écriture du
    // dossier, et son chemin de poussée (`POST /sync/enrollments`) exige aussi
    // `editique.write` — il scelle une attestation en inscrivant. Sans les deux
    // droits, laisser créer le brouillon fabriquerait une écriture que le
    // serveur rejettera définitivement au flush.
    if (!PermissionGate.allows(context, const [
      Perm.enrollmentWrite,
      Perm.editiqueWrite,
    ], requiresAll: true)) {
      return;
    }
    final yearId = academicYearContext?.academicYear.id;
    if (yearId == null || yearId.trim().isEmpty) return;
    _seededIntent = _effectiveIntent;
    final offline = context.read<EnrollmentOfflineBloc>();
    switch (_effectiveIntent.origin) {
      case EnrollmentDetailOrigin.reRegistration:
        final studentId = _effectiveIntent.studentId;
        if (studentId == null || studentId.trim().isEmpty) {
          _seededIntent = null;
          return;
        }
        offline.add(
          SeedFromCohortRequested(studentId: studentId, academicYearId: yearId),
        );
      case EnrollmentDetailOrigin.preRegistration:
        // Candidat brut (segment de route littéral `new`) : le vrai
        // preEnrollmentId est porté par `studentId` (slot réutilisé, cf.
        // `EnrollmentDetailIntent.preRegistration`) — jamais par
        // `enrollmentId`, qui vaut `new` tant qu'aucun dossier n'existe.
        final preEnrollmentId =
            _effectiveIntent.studentId ?? _effectiveIntent.enrollmentId;
        if (preEnrollmentId.trim().isEmpty) {
          _seededIntent = null;
          return;
        }
        offline.add(
          SeedFromPreEnrollmentRequested(
            preEnrollmentId: preEnrollmentId,
            academicYearId: yearId,
          ),
        );
      case EnrollmentDetailOrigin.newFirstRegistration:
      case EnrollmentDetailOrigin.firstRegistration:
      case EnrollmentDetailOrigin.localDraftResume:
        _seededIntent = null;
    }
  }

  // Rejoue le seed local (bouton « Réessayer » de l'écran d'erreur du seed).
  void _retryLocalSeed() {
    _seededIntent = null;
    _maybeSeedFromLocalRef(
      context.read<AcademicYearContextBloc>().state.context,
    );
  }

  // Sonde au tap RE/PRE : un dossier existe déjà pour ce candidat → on l'OUVRE
  // au lieu de seeder un doublon (le seed a été court-circuité côté bloc).
  // `DRAFT` → reprise éditable (chargement du brouillon par id) ; finalisé →
  // lecture seule (chargement local + bascule forcée, option b).
  void _onReenrollmentExisting(
    BuildContext context,
    EnrollmentOfflineState state,
  ) {
    if (state is! EnrollmentLocalDossierExisting) return;
    final bloc = context.read<EnrollmentOfflineBloc>();
    if (state.syncState == SyncState.draft) {
      bloc.add(LoadDraftDetailRequested(state.enrollmentId));
    } else {
      setState(() => _forceLocalReadOnly = true);
      bloc.add(LoadLocalEnrollmentDetail(state.enrollmentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      listenWhen: (previous, current) =>
          previous != current &&
          (current is EnrollmentOfflineDetailLoaded ||
              current is EnrollmentOfflineError),
      listener: _onLocalDetail,
      child: Builder(
        builder: (context) {
          // Dossier local (read-your-writes OU Première inscription) → lecture
          // seule, prioritaire sur les chemins draft/serveur.
          if (_localReadOnly != null) {
            return _buildLocalReadOnly(context, l10n);
          }
          // Première inscription : consultation LECTURE SEULE servie depuis le
          // local (aucun GET serveur). Tant que la lecture locale n'a pas
          // basculé `_localReadOnly`, on affiche le chargement/erreur pilotés
          // par le bloc offline.
          if (_isFirstRegistrationListing) {
            return _buildFirstRegistrationConsultation(context, l10n);
          }
          // Tout le reste (NEW / RE / PRE / reprise) édite un brouillon local :
          // ces origines ont toutes `usesLocalDraft == true`. La consultation
          // pure passe par `_localReadOnly` / la Première inscription ci-dessus,
          // jamais par un rendu piloté par le détail online.
          return _buildLocalDraft(context, l10n);
        },
      ),
    );
  }

  // Vue LECTURE SEULE d'un dossier local non synchronisé : agrégat reconstruit
  // depuis le local (mapper + bootstrap), rendu via le stepper en consultation.
  Widget _buildLocalReadOnly(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
      builder: (context, academicYearState) {
        final detail = mapLocalToEnrollmentDetail(
          _localReadOnly!,
          levels: schoolLevelsFromAcademicYearContext(
            academicYearState.context,
          ),
          groups: schoolLevelGroupsFromAcademicYearContext(
            academicYearState.context,
          ),
        );
        return EnrollmentJourneyScaffold(
          modeLabel: _buildJourneyModeLabel(l10n),
          studentDisplayName: _localDraftDisplayName(detail, l10n),
          currentStep: _currentStep,
          body: EnrollmentDetailContentShell(
            child: EnrollmentStepperScope(
              enrollmentDetail: detail,
              detailIntent: _effectiveIntent,
              detailPolicy: const LocalConsultationDetailPolicy(),
              onStepChanged: _onStepChanged,
            ),
          ),
        );
      },
    );
  }

  /// Première inscription : la page attend l'agrégat local (chargé via
  /// [LoadLocalEnrollmentDetail]). Le succès bascule `_localReadOnly`
  /// ([_onLocalDetail]) → cette vue ne rend donc que le chargement (sonde en
  /// vol) et l'erreur (dossier introuvable en local → « Réessayer » re-sonde).
  Widget _buildFirstRegistrationConsultation(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return EnrollmentJourneyScaffold(
      modeLabel: _buildJourneyModeLabel(l10n),
      studentDisplayName: l10n.enrollmentUnknownStudent,
      currentStep: _currentStep,
      body: BlocBuilder<EnrollmentOfflineBloc, EnrollmentOfflineState>(
        buildWhen: (previous, current) =>
            current is EnrollmentOfflineLoading ||
            current is EnrollmentOfflineError ||
            current is EnrollmentOfflineDetailLoaded,
        builder: (context, state) {
          if (state is EnrollmentOfflineError) {
            return EnrollmentDetailPageStateShell(
              child: EnrollmentDetailErrorTemplate(
                message: state.message,
                onRetry: () => context.read<EnrollmentOfflineBloc>().add(
                  LoadLocalEnrollmentDetail(_effectiveIntent.enrollmentId),
                ),
              ),
            );
          }
          return const EnrollmentDetailPageStateShell(
            child: EnrollmentDetailLoadingTemplate(),
          );
        },
      ),
    );
  }

  // Parcours brouillon (NEW/RE/PRE/reprise) : agrégat reconstruit depuis le
  // brouillon local (mapper). NEW démarre vierge (amorce ids + année courante) ;
  // RE/PRE seedent depuis le LOCAL (cohorte / préinscriptions) dès que l'année
  // courante est là ; la reprise d'un brouillon local charge l'agrégat par id.
  Widget _buildLocalDraft(BuildContext context, AppLocalizations l10n) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EnrollmentOfflineBloc, EnrollmentOfflineState>(
          listenWhen: (previous, current) =>
              previous != current &&
              (current is EnrollmentDraftStarted ||
                  current is EnrollmentDraftDetailLoaded),
          listener: _onDraftAggregateState,
        ),
        // Sonde au tap RE : dossier déjà existant → ouverture (reprise/lecture
        // seule) au lieu d'un seed en doublon.
        BlocListener<EnrollmentOfflineBloc, EnrollmentOfflineState>(
          listenWhen: (previous, current) =>
              previous != current && current is EnrollmentLocalDossierExisting,
          listener: _onReenrollmentExisting,
        ),
      ],
      child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        builder: (context, academicYearState) {
          // Seed local RE/PRE : déclenché après la frame (dispatch interdit
          // pendant build), dès que l'année courante est chargée ; idempotent
          // (garde _seededIntent), couvre le cas « bootstrap déjà en cache ».
          if (_policy.seedsFromLocalRef && _seededIntent != _effectiveIntent) {
            final academicYearContext = academicYearState.context;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _maybeSeedFromLocalRef(academicYearContext),
            );
          }
          final detail = _resolveLocalDraftDetail(academicYearState.context);
          _draftFormShown = detail != null;
          return _wrapWithExitGuard(
            EnrollmentJourneyScaffold(
              modeLabel: _buildJourneyModeLabel(l10n),
              studentDisplayName: _localDraftDisplayName(detail, l10n),
              currentStep: _currentStep,
              onExitRequested: _onExitRequested,
              body: detail == null
                  ? _buildLocalDraftPending()
                  : EnrollmentDetailContentShell(
                      child: EnrollmentStepperScope(
                        enrollmentDetail: detail,
                        detailIntent: _effectiveIntent,
                        detailPolicy: _policy,
                        onStepChanged: _onStepChanged,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  /// Brouillon pas encore prêt : NEW/reprise attendent l'amorce locale
  /// (spinner) ; RE/PRE suivent le seed LOCAL (échec = cohorte/snapshot non
  /// peuplés → écran d'erreur + « Réessayer »).
  Widget _buildLocalDraftPending() {
    if (_policy.seedsFromLocalRef) {
      // Seed depuis le local : l'échec (cohorte/préinscriptions non peuplées,
      // pull dormant) remonte en EnrollmentDraftError. La **sonde au tap** qui
      // ouvre un dossier finalisé charge le détail local (LoadLocalEnrollmentDetail)
      // dont l'échec remonte, lui, en EnrollmentOfflineError : sans le traiter ici,
      // la page resterait bloquée sur le spinner. Les deux → même écran d'erreur +
      // « Réessayer » (qui re-sonde via _retryLocalSeed).
      return BlocBuilder<EnrollmentOfflineBloc, EnrollmentOfflineState>(
        buildWhen: (previous, current) =>
            current is EnrollmentDraftError ||
            current is EnrollmentOfflineError ||
            current is EnrollmentDraftSaving ||
            current is EnrollmentDraftStarted,
        builder: (context, state) {
          final errorMessage = switch (state) {
            EnrollmentDraftError(:final message) => message,
            EnrollmentOfflineError(:final message) => message,
            _ => null,
          };
          if (errorMessage != null) {
            return EnrollmentDetailPageStateShell(
              child: EnrollmentDetailErrorTemplate(
                message: errorMessage,
                onRetry: _retryLocalSeed,
              ),
            );
          }
          return const EnrollmentDetailPageStateShell(
            child: EnrollmentDetailLoadingTemplate(),
          );
        },
      );
    }
    // NEW vierge / reprise d'un brouillon local : simple attente de l'amorce
    // locale (ids + année courante, ou chargement du brouillon par id) → spinner.
    return const EnrollmentDetailPageStateShell(
      child: EnrollmentDetailLoadingTemplate(),
    );
  }

  EnrollmentDetail? _resolveLocalDraftDetail(
    AcademicYearContext? academicYearContext,
  ) {
    final local = _draftLocal;
    final ids = _draftIds;

    if (_cachedAggregate != null &&
        identical(_cachedLocal, local) &&
        identical(_cachedIds, ids) &&
        identical(_cachedAcademicYearContext, academicYearContext)) {
      return _cachedAggregate;
    }

    final aggregate = _composeLocalDraftDetail(local, ids, academicYearContext);
    _cachedLocal = local;
    _cachedIds = ids;
    _cachedAcademicYearContext = academicYearContext;
    _cachedAggregate = aggregate;
    return aggregate;
  }

  EnrollmentDetail? _composeLocalDraftDetail(
    LocalEnrollmentDetail? local,
    DraftIds? ids,
    AcademicYearContext? academicYearContext,
  ) {
    if (local != null) {
      return mapLocalToEnrollmentDetail(
        local,
        levels: schoolLevelsFromAcademicYearContext(academicYearContext),
        groups: schoolLevelGroupsFromAcademicYearContext(academicYearContext),
      );
    }

    // Amorce vide : uniquement pour le brouillon vierge NEW — un parcours seedé
    // attend le détail local (jamais de formulaire vide flash sur RE/PRE).
    if (ids != null &&
        academicYearContext != null &&
        !_policy.requiresDraftSeed) {
      return buildDraftSeedDetail(
        enrollmentId: ids.enrollmentId,
        studentId: ids.studentId,
        academicYearId: academicYearContext.academicYear.id,
      );
    }

    return null;
  }

  String _localDraftDisplayName(
    EnrollmentDetail? detail,
    AppLocalizations l10n,
  ) {
    if (detail == null) {
      return l10n.enrollmentUnknownStudent;
    }
    final name = _buildStudentDisplayName(detail);
    return name.trim().isEmpty ? l10n.enrollmentUnknownStudent : name;
  }

  String _buildStudentDisplayName(EnrollmentDetail detail) {
    final fullName = [
      detail.studentDetail.firstName,
      detail.studentDetail.lastName,
      detail.studentDetail.surname,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return fullName.isNotEmpty
        ? fullName
        : detail.enrollmentDetail.enrollmentCode;
  }

  String _buildJourneyModeLabel(AppLocalizations l10n) {
    return switch (_effectiveIntent.origin) {
      EnrollmentDetailOrigin.newFirstRegistration => l10n.journeyModeNew,
      EnrollmentDetailOrigin.localDraftResume => l10n.journeyModeEdit,
      // Première inscription = consultation lecture seule locale (plus d'édition
      // d'un dossier synchronisé) → même libellé « Consulter » que RE/PRE.
      EnrollmentDetailOrigin.firstRegistration ||
      EnrollmentDetailOrigin.preRegistration ||
      EnrollmentDetailOrigin.reRegistration => l10n.journeyModeView,
    };
  }

  void _onStepChanged(int step) {
    if (_currentStep == step || !mounted) {
      return;
    }
    setState(() => _currentStep = step);
  }

  // ── Garde de sortie du wizard (brouillon en cours) ─────────────────────────

  /// Le formulaire du brouillon est effectivement affiché (agrégat composé).
  /// Faux sur le spinner d'amorce, l'écran d'erreur de seed (cohorte non
  /// peuplée, session gelée READ_ONLY) et la fenêtre transitoire de la sonde
  /// RE → la sortie y est libre : il n'y a rien à abandonner. Assigné pendant
  /// le build du flux brouillon (dérivé, pas un setState).
  bool _draftFormShown = false;

  /// Sortie confirmée requise : uniquement pendant un parcours d'édition de
  /// brouillon local (NEW/RE/PRE/reprise) dont le formulaire est matérialisé.
  /// La consultation lecture seule sort librement. La redirection de succès
  /// post-finalisation passe par `goNamed` (jamais un pop) → non interceptée.
  bool get _needsExitConfirmation =>
      _policy.usesLocalDraft && _localReadOnly == null && _draftFormShown;

  /// Anti double-dialogue : un second déclencheur (back système pendant que la
  /// popin de l'app bar est ouverte) est ignoré.
  bool _exitDialogOpen = false;

  Future<void> _onExitRequested() async {
    if (!_needsExitConfirmation) {
      _leaveJourney();
      return;
    }
    if (_exitDialogOpen) return;
    _exitDialogOpen = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      final confirmed = await showAppConfirmationDialog(
        context: context,
        title: l10n.wizardExitConfirmTitle,
        message: l10n.wizardExitConfirmMessage,
        confirmLabel: l10n.wizardExitConfirmAction,
        cancelLabel: l10n.wizardExitStayAction,
        isDestructive: true,
        headerIcon: Icons.logout_rounded,
        confirmIcon: Icons.logout_rounded,
      );
      if (!mounted || !confirmed) return;
      _leaveJourney();
    } finally {
      _exitDialogOpen = false;
    }
  }

  void _leaveJourney() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    // Wizard ouvert via `go` (pile déclarative remplacée) : retour au listing
    // Première inscription — même atterrissage que le chemin de succès.
    EnrollmentNavigationHelper.redirectToFirstRegistrationFromHome(context);
  }

  /// Enveloppe le flux brouillon dans un [PopScope] : le retour SYSTÈME
  /// (geste/bouton Android) passe par la même confirmation que les boutons de
  /// l'app bar. `context.pop()` de GoRouter (déclenché après confirmation)
  /// n'emprunte pas `maybePop` → il n'est pas re-intercepté.
  Widget _wrapWithExitGuard(Widget child) {
    return PopScope(
      canPop: !_needsExitConfirmation,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onExitRequested();
      },
      child: child,
    );
  }
}
