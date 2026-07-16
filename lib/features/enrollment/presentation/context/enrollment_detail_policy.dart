import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';

// Ordre du parcours (PARCOURS 20) : Tuteurs AVANT Frais. L'ordre de
// déclaration pilote step.index (natif), qui pilote à son tour order des
// handlers, la clé de la map d'états et la position dans le stepper — tout
// reste donc aligné.
enum EnrollmentWizardStep {
  personalInfo,
  address,
  previousAcademic,
  targetAcademic,
  guardian,
  studentCharges,
  summary,
}

extension EnrollmentWizardStepX on EnrollmentWizardStep {
  int get index => switch (this) {
    EnrollmentWizardStep.personalInfo => 0,
    EnrollmentWizardStep.address => 1,
    EnrollmentWizardStep.previousAcademic => 2,
    EnrollmentWizardStep.targetAcademic => 3,
    EnrollmentWizardStep.guardian => 4,
    EnrollmentWizardStep.studentCharges => 5,
    EnrollmentWizardStep.summary => 6,
  };

  static EnrollmentWizardStep fromIndex(int index) {
    return switch (index) {
      0 => EnrollmentWizardStep.personalInfo,
      1 => EnrollmentWizardStep.address,
      2 => EnrollmentWizardStep.previousAcademic,
      3 => EnrollmentWizardStep.targetAcademic,
      4 => EnrollmentWizardStep.guardian,
      5 => EnrollmentWizardStep.studentCharges,
      _ => EnrollmentWizardStep.summary,
    };
  }
}

abstract class EnrollmentDetailPolicy {
  const EnrollmentDetailPolicy();

  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  });

  EnrollmentLoadStatus loadStatus(EnrollmentState state);

  EnrollmentDetail? detail(EnrollmentState state);

  bool isStepEditable(EnrollmentWizardStep step);

  /// Le dossier est en consultation lecture seule intégrale (élève déjà
  /// inscrit, consultable mais non modifiable). Vrai uniquement quand même la
  /// première étape de données n'est pas éditable — ce qui n'arrive que dans
  /// les flux de consultation, jamais en création/édition (où seule l'étape
  /// Frais est verrouillée). Dérivé de [isStepEditable] → toujours cohérent.
  bool get isReadOnlyConsultation =>
      !isStepEditable(EnrollmentWizardStep.personalInfo);

  // ── Parcours offline-first : brouillon local par étape ──────────────────────

  /// Le parcours écrit dans le **brouillon local** par étape (puis 1 flush
  /// agrégat à la validation). Vrai pour toute création/édition — NEW, RE, PRE,
  /// reprise d'un dossier IN_PROGRESS — faux en consultation pure (aucune
  /// écriture possible). Dérivé de [isStepEditable] → toujours cohérent.
  bool get usesLocalDraft => !isReadOnlyConsultation;

  /// Un dossier chargé du serveur doit être **photographié** en brouillon
  /// local avant l'édition (RE/PRE/reprise). Faux pour NEW (brouillon vierge)
  /// et pour la consultation.
  bool get requiresDraftSeed => false;

  /// La photo de départ du brouillon est lue **depuis le local** (cohorte N-1 /
  /// préinscriptions) et non depuis un chargement serveur. Vrai pour RE/PRE : la
  /// page dispatche l'événement de seed offline dès que l'année courante
  /// (bootstrap) est disponible, `requestLoad` devient alors inerte.
  bool get seedsFromLocalRef => false;

  /// `enrollmentType` de l'agrégat porté par le brouillon (valeur API).
  String get draftEnrollmentType => 'NEW_ENROLLMENT';

  /// Statut métier initial du brouillon (valeur API).
  String get draftStatus => 'IN_PROGRESS';

  /// Id d'inscription à conserver au seed (id serveur connu : PRE, reprise) —
  /// null → uuid client neuf (NEW, RE : nouveau dossier pour l'année N).
  String? seedEnrollmentId(EnrollmentDetailIntent intent) => null;

  /// Référence d'origine du dossier (contrat agrégat) : id de préinscription
  /// (PRE). RE = matricule — indisponible sur le détail online (le `studentId`
  /// canonique de l'agrégat suffit au serveur) : sera fourni par le seed
  /// depuis la cohorte locale `ref_previous_year_students` (étape c).
  String? seedSourceRef(EnrollmentDetailIntent intent) => null;

  bool canSaveStep(EnrollmentWizardStep step) {
    // Le step récapitulatif déclenche la validation du dossier :
    // il est toujours actionnable (l'enrollment ID est vérifié au dispatch).
    if (step == EnrollmentWizardStep.summary) return true;
    return isStepEditable(step);
  }

  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => false;

  bool requiresPreviousYearBootstrap(EnrollmentDetailIntent intent) => false;
}

/// Consultation **lecture seule d'un dossier LOCAL** (read-your-writes) : un
/// dossier créé sur la tablette et pas encore synchronisé, ouvert depuis le
/// listing. Toutes les étapes sont non-éditables (le dossier est déjà finalisé
/// et en file de synchro — la ré-édition d'un PENDING_SYNC n'est pas supportée
/// par le DAO draft) ; le détail est fourni directement par la page (mappé
/// depuis le local), pas via l'état online → `detail`/`requestLoad` inertes.
class LocalConsultationDetailPolicy extends EnrollmentDetailPolicy {
  const LocalConsultationDetailPolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => null;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) =>
      EnrollmentLoadStatus.success;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {}

  @override
  bool isStepEditable(EnrollmentWizardStep step) => false;

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;
}

class EnrollmentDetailPolicyResolver {
  const EnrollmentDetailPolicyResolver._();

  static EnrollmentDetailPolicy fromIntent(EnrollmentDetailIntent intent) {
    return switch (intent.origin) {
      EnrollmentDetailOrigin.preRegistration =>
        const PreRegistrationDetailPolicy(),
      EnrollmentDetailOrigin.reRegistration =>
        const ReRegistrationDetailPolicy(),
      EnrollmentDetailOrigin.firstRegistration => FirstRegistrationDetailPolicy(
        status: intent.status,
      ),
      EnrollmentDetailOrigin.newFirstRegistration =>
        const NewFirstRegistrationDetailPolicy(),
      EnrollmentDetailOrigin.localDraftResume =>
        const LocalDraftResumeDetailPolicy(),
    };
  }
}

/// Reprise d'un **brouillon LOCAL** (`sync_status = DRAFT`) déjà persisté en
/// base, ouvert depuis le listing pour être finalisé. L'agrégat existe déjà
/// localement : **aucun seed** (ni serveur ni cohorte) et **aucun GET online**
/// (l'`enrollmentId` est un id client → 404). La page charge le brouillon par
/// id (`LoadDraftDetailRequested`) puis l'édite par étape comme un NEW, jusqu'à
/// la finalisation (`DRAFT → PENDING_SYNC`). Éditable partout sauf le
/// récapitulatif (comme NEW) → `usesLocalDraft` vrai, `requiresDraftSeed` faux.
class LocalDraftResumeDetailPolicy extends EnrollmentDetailPolicy {
  const LocalDraftResumeDetailPolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  /// Inerte : le brouillon est déjà en base locale (chargé via
  /// `LoadDraftDetailRequested`) — un GET serveur sur un id client échouerait.
  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {}

  @override
  bool isStepEditable(EnrollmentWizardStep step) =>
      step != EnrollmentWizardStep.summary;

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;
}

class PreRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  const PreRegistrationDetailPolicy();

  @override
  bool get requiresDraftSeed => true;

  /// Seed lu depuis `ref_pre_enrollments` (local), plus depuis un GET serveur.
  @override
  bool get seedsFromLocalRef => true;

  @override
  String get draftEnrollmentType => 'PRE_ENROLLMENT';

  @override
  String get draftStatus => 'PRE_REGISTERED';

  /// La préinscription EST un dossier serveur : l'id est conservé (idempotence
  /// G2 au push) et sert de référence d'origine.
  @override
  String? seedEnrollmentId(EnrollmentDetailIntent intent) =>
      intent.enrollmentId;

  @override
  String? seedSourceRef(EnrollmentDetailIntent intent) => intent.enrollmentId;

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  /// Inerte : le seed PRE vient du local (voir [seedsFromLocalRef]).
  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {}

  @override
  bool isStepEditable(EnrollmentWizardStep step) =>
      step != EnrollmentWizardStep.summary;

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;
}

class ReRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  const ReRegistrationDetailPolicy();

  @override
  bool get requiresDraftSeed => true;

  /// Seed lu depuis `ref_previous_year_students` (cohorte N-1 locale), plus
  /// depuis le preview serveur.
  @override
  bool get seedsFromLocalRef => true;

  @override
  String get draftEnrollmentType => 'RE_ENROLLMENT';

  @override
  String get draftStatus => 'PRE_REGISTERED';

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.preview;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.previewStatus;

  /// Inerte : le seed RE vient de la cohorte locale (voir [seedsFromLocalRef]).
  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {}

  @override
  bool isStepEditable(EnrollmentWizardStep step) {
    // La règle initiale garde l'expérience existante; elle peut évoluer
    // sans modifier le stepper ni la page détail.
    return step != EnrollmentWizardStep.summary;
  }

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;

  @override
  bool requiresPreviousYearBootstrap(EnrollmentDetailIntent intent) => true;
}

class FirstRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  final String? status;

  const FirstRegistrationDetailPolicy({this.status});

  /// Reprise d'un dossier IN_PROGRESS : le dossier serveur est photographié en
  /// brouillon local (id conservé — idempotence G2) puis édité par étape.
  @override
  bool get requiresDraftSeed => usesLocalDraft;

  @override
  String? seedEnrollmentId(EnrollmentDetailIntent intent) =>
      intent.enrollmentId;

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {
    bloc.add(
      EnrollmentDetailRequested(
        enrollmentId: intent.enrollmentId,
        silent: silent,
      ),
    );
  }

  @override
  bool isStepEditable(EnrollmentWizardStep step) {
    final normalizedStatus = status?.trim().toUpperCase();
    if (normalizedStatus != 'IN_PROGRESS') {
      return false;
    }

    return step != EnrollmentWizardStep.summary;
  }

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;
}

class NewFirstRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  const NewFirstRegistrationDetailPolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {
    // NEW : plus aucun chargement online — la page démarre directement le
    // brouillon local vierge. Reste le cas défensif d'un id concret sur route.
    if (intent.enrollmentId == 'new') {
      return;
    }

    bloc.add(
      EnrollmentDetailRequested(
        enrollmentId: intent.enrollmentId,
        silent: silent,
      ),
    );
  }

  @override
  bool isStepEditable(EnrollmentWizardStep step) =>
      step != EnrollmentWizardStep.summary;

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;
}
