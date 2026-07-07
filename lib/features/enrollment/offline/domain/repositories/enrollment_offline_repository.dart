import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Draft d'un tuteur saisi (le repo générera l'uuid provisoire).
class ConfirmParentDraft {
  final String firstName;
  final String lastName;
  final String? surname;
  final String phoneNumber;
  final String? email;
  final String relationshipType; // valeur API SCREAMING_SNAKE

  const ConfirmParentDraft({
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    this.email,
    this.relationshipType = 'OTHER',
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
  final String? phoneNumber;
  final String? matriculationNumber; // non-null en RE (cohorte)

  final String enrollmentType; // NEW_ENROLLMENT|RE_ENROLLMENT|PRE_ENROLLMENT
  final String status; // IN_PROGRESS (NEW) | PRE_REGISTERED (RE/PRE)
  final String academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String enrollmentDate; // yyyy-MM-dd (date terrain)
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;
  final String? transferReason;
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
    this.phoneNumber,
    this.matriculationNumber,
    required this.enrollmentType,
    required this.status,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
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
  /// Confirme un dossier (transaction locale + enqueue outbox). Renvoie l'id
  /// d'inscription (uuid client) immédiatement, sans attente réseau.
  Future<Either<Failure, String>> confirmEnrollment(
    ConfirmEnrollmentDraft draft,
  );

  // ── Wizard offline-first : brouillon local persisté (M1) ────────────────────

  /// Démarre un brouillon : génère (sans écrire) les ids client. `studentId`
  /// réutilise `existingStudentId` s'il est fourni (RE/PRE), sinon un uuid neuf
  /// (NEW) ; `enrollmentId` est toujours un uuid neuf.
  DraftIds startDraft({String? existingStudentId});

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
  });

  /// Étape Adresse : UPDATE partiel de l'élève DRAFT (colonnes non-null).
  Future<Either<Failure, Unit>> saveDraftAddress({
    required String studentId,
    String? city,
    String? district,
    String? municipality,
    String? neighborhood,
    String? address,
    String? phoneNumber,
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
    String? transferReason,
  });

  /// Étape Affectation : UPDATE partiel de l'inscription DRAFT (niveau visé).
  Future<Either<Failure, Unit>> saveDraftTargetAcademic({
    required String enrollmentId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  });

  /// Étape Tuteurs : remplace les tuteurs du brouillon (ids provisoires générés).
  Future<Either<Failure, Unit>> saveDraftGuardians({
    required String studentId,
    required List<ConfirmParentDraft> parents,
  });

  /// Détail du brouillon (élève + tuteurs + documents). NotFound si absent.
  Future<Either<Failure, LocalEnrollmentDetail>> getDraftDetail(
    String enrollmentId,
  );

  /// Étape Résumé : DRAFT → PENDING_SYNC + document provisoire + enqueue outbox
  /// idempotente, puis flush opportuniste. NotFound si déjà confirmé/absent.
  Future<Either<Failure, Unit>> finalizeDraft({
    required String enrollmentId,
    bool emitDocument = true,
  });

  Future<Either<Failure, List<LocalEnrollmentListItem>>> getEnrollments({
    String? status,
  });

  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByName(
    String query,
  );

  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByDateOfBirth(
    String dateOfBirth,
  );

  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByAcademicInfo({
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  });

  Future<Either<Failure, LocalEnrollmentDetail>> getDetail(String enrollmentId);
}
