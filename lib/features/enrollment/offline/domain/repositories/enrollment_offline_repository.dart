import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Draft d'un tuteur saisi.
class ConfirmParentDraft {
  /// Id stable porté par l'UI (miné côté client à la création du tuteur, ou
  /// id réel d'un parent existant choisi via "Rechercher un parent"). `null`
  /// seulement pour les seeds RE/PRE (`EnrollmentConfirmDraftBuilder`) :
  /// `seedDraft` l'ignore et garde son comportement historique (mint son
  /// propre uuid, dédup par téléphone via `upsertParentByPhone`).
  final String? id;

  /// true si ce tuteur a été choisi via "Rechercher un parent" (l'id
  /// référence une fiche RÉELLE déjà en base, jamais réécrite).
  final bool isLinkedToExisting;
  final String firstName;
  final String lastName;
  final String? surname;
  final String? phoneNumber;
  final String? email;
  final String relationshipType; // valeur API SCREAMING_SNAKE

  /// Tuteur à appeler en urgence pour CET élève — au plus un par élève.
  /// **Tri-état conservé jusqu'au fil** : `true` désigne (et démote les
  /// autres), `false` retire celui-là, `null` ne dit rien. Aplatir `null` en
  /// `false` effacerait une désignation venue d'ailleurs.
  final bool? emergencyContact;

  const ConfirmParentDraft({
    this.id,
    this.isLinkedToExisting = false,
    required this.firstName,
    required this.lastName,
    this.surname,
    this.phoneNumber,
    this.email,
    this.relationshipType = 'OTHER',
    this.emergencyContact,
  });
}

/// Draft d'une confirmation d'inscription (entrée du chemin local-first).
///
/// `studentId` non-null = RE/PRE (élève préexistant serveur, matricule connu) ;
/// null = NEW (le repo génère l'uuid client, matricule « en cours »).
class ConfirmEnrollmentDraft {
  final String? studentId;
  final String firstName;
  final String lastName;
  final String? surname;
  final String gender; // MALE|FEMALE|OTHER
  final String dateOfBirth; // yyyy-MM-dd
  final String? birthPlace;
  final String? nationality;
  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;
  final String? matriculationNumber; // non-null en RE (cohorte)

  final String enrollmentType; // NEW_ENROLLMENT|RE_ENROLLMENT|PRE_ENROLLMENT
  final String status; // IN_PROGRESS (NEW/RE) | PRE_REGISTERED (PRE)

  /// Référence d'origine du dossier (contrat agrégat) : matricule (RE),
  /// id de préinscription (PRE), null (NEW).
  final String? sourceRef;
  final String academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String enrollmentDate; // yyyy-MM-dd (date terrain)
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;

  /// Id référentiel du niveau N-1 (distinct du texte libre
  /// [previousSchoolLevel]) — connu uniquement en réinscription
  /// (`ReenrollmentCandidate.previousSchoolLevelId`), alimente le calcul
  /// auto de la classe cible. Pas un champ édité par le wizard.
  final String? previousSchoolLevelId;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;
  final String? transferReason;

  /// « Ancien élève de l'école » à la photo de départ. `true` par construction
  /// en réinscription : le dossier vient d'une inscription de l'année
  /// précédente DANS cette école.
  final bool formerStudent;

  /// Fiche santé reprise du dossier N-1. **C'est une proposition** que le
  /// guichet relit à l'étape Identité ; elle ne devient la valeur de la
  /// nouvelle inscription que si l'agrégat la repousse.
  final String? medicalNotes;
  final bool emitDocument;

  final List<ConfirmParentDraft> parents;

  const ConfirmEnrollmentDraft({
    this.studentId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.gender,
    required this.dateOfBirth,
    this.birthPlace,
    this.nationality,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
    this.matriculationNumber,
    required this.enrollmentType,
    required this.status,
    this.sourceRef,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.previousSchoolLevelId,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.formerStudent = false,
    this.medicalNotes,
    this.transferReason,
    this.emitDocument = true,
    this.parents = const [],
  });
}

/// Couple d'identifiants client figés au démarrage d'un brouillon de wizard
/// (aucune écriture DB à ce stade : les colonnes NOT NULL empêchent d'insérer
/// une ligne vide, l'insertion réelle a lieu à l'étape 0 `saveDraftIdentity`).
class DraftIds {
  final String enrollmentId;
  final String studentId;

  const DraftIds({required this.enrollmentId, required this.studentId});
}

/// Repository offline-first du module Inscription : écritures local-first
/// (confirmation) et lectures servies depuis sqflite.
abstract class EnrollmentOfflineRepository {
  // ── Wizard offline-first : brouillon local persisté (M1) ────────────────────

  /// Démarre un brouillon : génère (sans écrire) les ids client. `studentId`
  /// réutilise `existingStudentId` s'il est fourni (RE/PRE), sinon un uuid neuf
  /// (NEW) ; `enrollmentId` est toujours un uuid neuf.
  DraftIds startDraft({String? existingStudentId});

  /// Amorce un brouillon **complet** (RE/PRE/édition) depuis un dossier chargé
  /// — la photo de départ que les étapes éditeront colonne-à-colonne.
  /// `enrollmentId` conserve un id serveur connu (PRE, édition) ; absent →
  /// uuid client neuf (RE, nouveau dossier N). `seed.studentId` connu = élève
  /// canonique (RE/PRE) ; null = uuid neuf. ValidationFailure si un dossier
  /// local de même id est déjà confirmé (non-DRAFT).
  Future<Either<Failure, DraftIds>> seedDraft(
    ConfirmEnrollmentDraft seed, {
    String? enrollmentId,
  });

  /// Étape 0 : crée les 2 lignes DRAFT (élève + inscription) — porte tous les
  /// champs NOT NULL. Ré-appelable (remplace la ligne de même id).
  Future<Either<Failure, Unit>> saveDraftIdentity({
    required String enrollmentId,
    required String studentId,
    required String firstName,
    required String lastName,
    String? surname,
    required String gender,
    required String dateOfBirth,
    String? birthPlace,
    String? nationality,
    String? matriculationNumber,
    required String enrollmentType,
    required String status,
    required String academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
    required String enrollmentDate,
    String? medicalNotes,

    /// [reopenEnrollmentId] — **correction d'un dossier déjà finalisé** : le
    /// dossier est ré-ouvert (`SYNCED|SYNC_ERROR → DRAFT`) dans la transaction de
    /// cette écriture, jamais avant. Ré-ouvrir à l'ouverture de l'écran sortirait
    /// de la facturation un dossier qu'on ne fait que consulter ; ré-ouvrir dans
    /// une transaction séparée laisserait, si l'écriture échoue, un dossier
    /// déclassé sans la moindre correction pour le justifier. `null` (défaut) =
    /// parcours de création, rien n'est ré-ouvert.
    String? reopenEnrollmentId,
  });

  /// Étape Adresse : UPDATE partiel de l'élève DRAFT (colonnes non-null).
  ///
  /// Pas de téléphone : `students.phone_number` est inerte depuis la v27
  /// (ADR-015 F8). Le paramètre existait, aucune étape ne le passait, et le
  /// payload de push n'a jamais porté de téléphone d'élève — il n'aurait donc
  /// fait qu'écrire de la donnée personnelle dans une colonne sans lecteur.
  Future<Either<Failure, Unit>> saveDraftAddress({
    required String studentId,
    String? city,
    String? district,
    String? municipality,
    String? neighborhood,
    String? address,
    String? reopenEnrollmentId,
  });

  /// Étape Antécédents : UPDATE partiel de l'inscription DRAFT (previous_*).
  Future<Either<Failure, Unit>> saveDraftPreviousAcademic({
    required String enrollmentId,
    String? previousSchoolName,
    String? previousAcademicYear,
    String? previousSchoolLevelGroup,
    String? previousSchoolLevel,
    double? previousRate,
    int? previousRank,
    bool? validatedPreviousYear,
    bool? formerStudent,
    String? transferReason,
    String? reopenEnrollmentId,
  });

  /// Étape Affectation : UPDATE partiel de l'inscription DRAFT (niveau visé).
  Future<Either<Failure, Unit>> saveDraftTargetAcademic({
    required String enrollmentId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
    String? reopenEnrollmentId,
  });

  /// Étape Tuteurs : remplace les tuteurs du brouillon (ids provisoires générés).
  Future<Either<Failure, Unit>> saveDraftGuardians({
    required String studentId,
    required List<ConfirmParentDraft> parents,
    String? reopenEnrollmentId,
  });

  /// Recherche de tuteurs déjà connus en local (popin "Rechercher un
  /// parent" de l'étape Tuteurs) : au moins un critère requis, sinon liste
  /// vide sans requête SQL.
  Future<Either<Failure, List<LocalParent>>> searchParents({
    String? firstName,
    String? lastName,
    String? surname,
    String? phoneNumber,
    int limit = 20,
  });

  /// Détail du brouillon (élève + tuteurs + documents). NotFound si absent.
  Future<Either<Failure, LocalEnrollmentDetail>> getDraftDetail(
    String enrollmentId,
  );

  /// Étape Résumé : DRAFT → PENDING_SYNC + document provisoire + enqueue outbox
  /// idempotente, puis flush opportuniste. NotFound si déjà confirmé/absent.
  /// [finalStatus] : statut métier à écrire explicitement (PRE → `COMPLETED`) ;
  /// `null` ne touche pas `status` (NEW/RE restent `IN_PROGRESS` en continu).
  Future<Either<Failure, Unit>> finalizeDraft({
    required String enrollmentId,
    bool emitDocument = true,
    String? finalStatus,
  });

  Future<Either<Failure, List<LocalEnrollmentListItem>>> getEnrollments({
    String? status,
    String? academicYearId,
    String? enrollmentType,
  });

  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByAcademicInfo({
    String? status,
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
    String? enrollmentType,
  });

  /// Recherche **Facturation** : les élèves réellement inscrits l'année courante
  /// (dossiers finalisés `sync_status` SYNCED|PENDING_SYNC|SYNC_ERROR),
  /// optionnellement bornés au groupe de niveau / niveau. [academicYearId] non
  /// fourni → résolu via l'année courante locale (`is_current`) ; non résolue →
  /// liste vide.
  Future<Either<Failure, List<LocalEnrollmentListItem>>>
  searchCurrentYearEnrolledByAcademicInfo({
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  });

  /// Recherche de **réinscription** : le vivier N-1 (cohorte locale filtrée par
  /// niveau) + les dossiers locaux de l'année **courante** (résolue via
  /// `is_current`) pour la superposition read-your-writes. Le scope année
  /// courante évite qu'un dossier N-1 terminé masque le candidat à réinscrire.
  Future<Either<Failure, ReenrollmentSearchResult>> searchReenrollmentCohort({
    String? schoolLevelId,
    String? schoolLevelGroupId,
  });

  /// Recherche de **pré-inscription** : le vivier `ref_pre_enrollments` (filtré
  /// par niveau souhaité) + les dossiers PRE locaux de l'année **courante**
  /// (résolue via `is_current`) pour la superposition read-your-writes. Même
  /// principe que [searchReenrollmentCohort], sans notion d'établissement
  /// précédent (une préinscription n'en a pas).
  Future<Either<Failure, PreEnrollmentSearchResult>> searchPreEnrollmentCohort({
    String? schoolLevelId,
    String? schoolLevelGroupId,
  });

  /// **Sonde au tap** RE : renvoie la référence d'un dossier local existant pour
  /// `(studentId, academicYearId)` — `null` si aucun. Backstop robuste contre une
  /// liste périmée / une année divergente : au tap d'un candidat, on ré-résout
  /// par `studentId` pour ouvrir le dossier existant (reprise/lecture seule)
  /// plutôt que de seeder un doublon.
  Future<Either<Failure, LocalDossierRef?>> probeLocalReenrollmentDossier({
    required String studentId,
    required String academicYearId,
  });

  /// Vrai si `studentId` est **déjà connu du serveur** (ligne `students` passée
  /// `SYNCED`, ou id canonique issu de la cohorte N-1). C'est la garde des
  /// pièces d'éditique scopées élève : un uuid client encore en attente de
  /// synchro produit un 404. **Fail-closed** — inconnu vaut « non ».
  Future<Either<Failure, bool>> isStudentKnownToServer(String studentId);

  Future<Either<Failure, LocalEnrollmentDetail>> getDetail(String enrollmentId);

  /// Candidat de réinscription (cohorte N-1 locale) par `student_id` — photo de
  /// départ du brouillon RE. `NotFoundFailure` si la cohorte n'est pas peuplée
  /// (pull dormant) ou l'élève absent.
  Future<Either<Failure, ReenrollmentCandidate>> getReenrollmentCandidate(
    String studentId,
  );

  /// Préinscription locale par `id` — photo de départ du brouillon PRE.
  /// `NotFoundFailure` si le snapshot n'est pas peuplé (pull dormant) ou absente.
  Future<Either<Failure, PreEnrollmentCandidate>> getPreEnrollment(
    String preEnrollmentId,
  );
}
