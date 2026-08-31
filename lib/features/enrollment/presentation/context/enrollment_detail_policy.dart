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

  /// La ré-hydratation entre étapes relit l'agrégat local **entier**
  /// (`LoadLocalEnrollmentDetail`) plutôt que le brouillon par id
  /// (`LoadDraftDetailRequested`).
  ///
  /// Vrai pour la correction d'un dossier complété, et pour elle seule : cet
  /// écran est rendu depuis l'agrégat local (le même que la consultation), pas
  /// depuis l'état « brouillon » de la page. Relire le mauvais des deux
  /// laisserait l'écran sur les données d'avant la correction — enregistrée en
  /// base, invisible à l'écran.
  bool get refreshesFromLocalAggregate => false;

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

  /// Statut métier à écrire explicitement à la finalisation (valeur API).
  /// `null` = ne pas toucher `status` (NEW/RE restent `IN_PROGRESS` en
  /// continu, la distinction "finalisé" venant de l'état de synchro, pas
  /// d'un changement de statut). Non-`null` pour PRE (`COMPLETED`), qui a
  /// besoin d'un vrai changement de statut pastille à 2 états.
  String? get finalizeStatus => null;

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
      EnrollmentDetailOrigin.localDraftResume => LocalDraftResumeDetailPolicy(
        enrollmentType: intent.enrollmentType,
      ),
      EnrollmentDetailOrigin.completedReedition =>
        CompletedReeditionDetailPolicy(enrollmentType: intent.enrollmentType),
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
  /// Type réel du dossier repris (porté par le listing au tap —
  /// `EnrollmentSummary.enrollmentType`). Sans lui, un re-save d'identité
  /// écraserait un brouillon RE/PRE avec le défaut NEW (`insertDraftEnrollment`
  /// écrit `draftEnrollmentType` sans condition) : null → défaut NEW, cohérent
  /// pour un vrai brouillon NEW.
  final String? enrollmentType;

  const LocalDraftResumeDetailPolicy({this.enrollmentType});

  @override
  String get draftEnrollmentType => enrollmentType ?? super.draftEnrollmentType;

  /// DÉRIVÉ du type, PAS de la valeur `status` persistée en base : un
  /// brouillon RE (ou PRE) créé avant l'alignement sur `IN_PROGRESS` porte
  /// encore un status legacy (`PRE_REGISTERED`) (aucun mécanisme de migration
  /// n'existe ailleurs pour ces lignes déjà persistées —
  /// `insertDraftEnrollment` écrit tel quel ce qu'on lui donne). Dériver du
  /// type fait que ce brouillon legacy se corrige tout seul au prochain
  /// re-save au lieu de rester figé — NEW/RE/PRE partagent tous `IN_PROGRESS`
  /// pendant la saisie (PRE ne se distingue qu'à la finalisation, cf.
  /// [finalizeStatus]).
  @override
  String get draftStatus => 'IN_PROGRESS';

  /// Un brouillon PRE repris doit finaliser vers `COMPLETED` (pas
  /// `IN_PROGRESS` en continu comme RE) : la pastille PRE n'a que 2 états.
  @override
  String? get finalizeStatus =>
      enrollmentType == 'PRE_ENROLLMENT' ? 'COMPLETED' : null;

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

/// Correction d'un dossier **déjà complété**.
///
/// Le dossier est en base, finalisé (`SYNCED`, parfois `SYNC_ERROR`) : aucun
/// seed, aucun GET serveur — comme [LocalDraftResumeDetailPolicy], dont elle ne
/// diffère que sur deux points, tous deux dictés par le fait que le dossier a
/// déjà produit ses effets.
///
/// **Le niveau visé et les Frais restent en lecture seule.** Les créances ont
/// été projetées à la confirmation, et leur matérialisation est idempotente :
/// changer le niveau après coup laisserait l'élève inscrit dans un niveau et
/// facturé sur la grille d'un autre, sans que rien ne le signale. Le serveur
/// refuse d'ailleurs le changement (`422 LEVEL_CHANGE_NOT_SUPPORTED`) ; l'écran
/// n'invite donc pas à une saisie qui serait rejetée. Changer de niveau reste
/// possible — par le parcours qui sait le faire, pas par une correction de
/// fiche.
///
/// **La finalisation écrit `IN_PROGRESS`.** C'est l'état local d'un dossier
/// corrigé et remis dans la file d'envoi, pas encore parti ; le serveur, lui,
/// re-dérive `COMPLETED` à l'ingestion et le pull le ramènera.
///
/// La ré-ouverture du dossier en brouillon n'est PAS portée ici : elle a lieu à
/// la première sauvegarde d'étape, dans sa transaction
/// (`ReeditionSessionStarted`). Ouvrir un dossier pour le consulter ne doit pas
/// le sortir de la facturation.
class CompletedReeditionDetailPolicy extends EnrollmentDetailPolicy {
  /// Type réel du dossier corrigé (NEW/RE), porté par le listing au tap : sans
  /// lui, un re-save d'identité écraserait le type par le défaut NEW.
  final String? enrollmentType;

  const CompletedReeditionDetailPolicy({this.enrollmentType});

  @override
  String get draftEnrollmentType => enrollmentType ?? super.draftEnrollmentType;

  @override
  String get draftStatus => 'IN_PROGRESS';

  @override
  String? get finalizeStatus => 'IN_PROGRESS';

  @override
  bool get refreshesFromLocalAggregate => true;

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  /// Inerte : le dossier est déjà en base locale (chargé par id).
  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {}

  @override
  bool isStepEditable(EnrollmentWizardStep step) => switch (step) {
    EnrollmentWizardStep.summary => false,
    EnrollmentWizardStep.targetAcademic => false,
    EnrollmentWizardStep.studentCharges => false,
    _ => true,
  };

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

  /// Même cycle que NEW/RE pendant la saisie : le brouillon doit apparaître
  /// dans le listing Première inscription (`draftEnrollmentType` — pastille
  /// « Pré-inscription » — le distingue, pas le status). `COMPLETED` n'est
  /// écrit qu'à la finalisation, cf. [finalizeStatus].
  @override
  String get draftStatus => 'IN_PROGRESS';

  /// PRE n'a que 2 états (pas de 3e pastille "candidat non engagé" comme RE) :
  /// la finalisation doit donc écrire explicitement `COMPLETED`.
  @override
  String? get finalizeStatus => 'COMPLETED';

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

  /// Même cycle que NEW (`IN_PROGRESS`) : le brouillon doit apparaître dans
  /// le listing Première inscription — `draftEnrollmentType` (pastille
  /// « Réinscription ») le distingue, pas le status.
  @override
  String get draftStatus => 'IN_PROGRESS';

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

/// `status`/`isStepEditable` ci-dessous ne sont plus jamais consultés côté
/// rendu pour cette origine : `EnrollmentDetailPage` court-circuite TOUJOURS
/// `firstRegistration` vers `LocalConsultationDetailPolicy` (lecture seule
/// 100% locale, fix #19) avant d'atteindre le stepper qui les lirait. Gardés
/// pour la résolution/les tests, pas un gate live — ne pas s'y fier pour
/// raisonner sur l'éditabilité réelle d'un dossier Première inscription.
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
