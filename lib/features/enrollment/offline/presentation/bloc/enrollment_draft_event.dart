import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';

// Événements du **brouillon par étape** du wizard — membres de la famille
// unique [EnrollmentOfflineEvent] (bloc Inscription offline fusionné), gardés
// dans leur fichier pour la lisibilité (1 famille, 2 fichiers thématiques).

/// Démarre un brouillon : fige les ids client (studentId réutilisé en RE/PRE).
class StartDraftRequested extends EnrollmentOfflineEvent {
  final String? existingStudentId;

  const StartDraftRequested({this.existingStudentId});

  @override
  List<Object?> get props => [existingStudentId];
}

/// Étape 0 : crée les 2 lignes DRAFT (élève + inscription).
class SaveDraftIdentityRequested extends EnrollmentOfflineEvent {
  final String enrollmentId;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? surname;
  final String gender;
  final String dateOfBirth;
  final String? birthPlace;
  final String? nationality;
  final String? matriculationNumber;
  final String enrollmentType;
  final String status;
  final String academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String enrollmentDate;

  /// Fiche santé de l'enfant, portée par l'INSCRIPTION même si elle se saisit
  /// à l'étape Identité : côté serveur `saveStudent` est un get-or-return, et
  /// une note posée sur l'élève serait figée à vie dès la première saisie.
  ///
  /// `null` = cette étape n'en dit rien (le brouillon garde ce qu'il a) ;
  /// chaîne vide = le guichet la vide. Donnée de santé — jamais journalisée.
  final String? medicalNotes;

  const SaveDraftIdentityRequested({
    required this.enrollmentId,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.gender,
    required this.dateOfBirth,
    this.birthPlace,
    this.nationality,
    this.matriculationNumber,
    required this.enrollmentType,
    required this.status,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
    this.medicalNotes,
  });

  @override
  List<Object?> get props => [
    enrollmentId,
    studentId,
    firstName,
    lastName,
    surname,
    gender,
    dateOfBirth,
    birthPlace,
    nationality,
    matriculationNumber,
    enrollmentType,
    status,
    academicYearId,
    schoolLevelId,
    schoolLevelGroupId,
    enrollmentDate,
    medicalNotes,
  ];
}

/// Étape Adresse.
class SaveDraftAddressRequested extends EnrollmentOfflineEvent {
  final String studentId;
  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;

  const SaveDraftAddressRequested({
    required this.studentId,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
  });

  @override
  List<Object?> get props => [
    studentId,
    city,
    district,
    municipality,
    neighborhood,
    address,
  ];
}

/// Étape Antécédents scolaires.
class SaveDraftPreviousAcademicRequested extends EnrollmentOfflineEvent {
  final String enrollmentId;
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;

  /// « Ancien élève de cette école », déclaré au guichet. Omis (`null`), il
  /// garde sa valeur : sa colonne est NOT NULL, et une étape qui ne le dit pas
  /// ne doit pas le remettre à faux.
  final bool? formerStudent;
  final String? transferReason;

  const SaveDraftPreviousAcademicRequested({
    required this.enrollmentId,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.formerStudent,
    this.transferReason,
  });

  @override
  List<Object?> get props => [
    enrollmentId,
    previousSchoolName,
    previousAcademicYear,
    previousSchoolLevelGroup,
    previousSchoolLevel,
    previousRate,
    previousRank,
    validatedPreviousYear,
    formerStudent,
    transferReason,
  ];
}

/// Étape Affectation (niveau visé).
class SaveDraftTargetAcademicRequested extends EnrollmentOfflineEvent {
  final String enrollmentId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;

  const SaveDraftTargetAcademicRequested({
    required this.enrollmentId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => [enrollmentId, schoolLevelId, schoolLevelGroupId];
}

/// Étape Tuteurs.
class SaveDraftGuardiansRequested extends EnrollmentOfflineEvent {
  final String studentId;
  final List<ConfirmParentDraft> parents;

  const SaveDraftGuardiansRequested({
    required this.studentId,
    required this.parents,
  });

  @override
  List<Object?> get props => [studentId, parents.length];
}

/// Ouvre une **session de correction** d'un dossier déjà complété : le dossier
/// nommé sera ré-ouvert (`SYNCED|SYNC_ERROR → DRAFT`) au moment de la première
/// sauvegarde d'étape, dans sa transaction.
///
/// N'écrit rien par elle-même : tant qu'un dossier est en brouillon il sort de
/// la recherche « élèves réellement inscrits » de la facturation, et ouvrir un
/// dossier pour le consulter ne doit pas l'en sortir.
class ReeditionSessionStarted extends EnrollmentOfflineEvent {
  final String enrollmentId;

  const ReeditionSessionStarted(this.enrollmentId);

  @override
  List<Object?> get props => [enrollmentId];
}

/// Charge le détail du brouillon.
class LoadDraftDetailRequested extends EnrollmentOfflineEvent {
  final String enrollmentId;

  const LoadDraftDetailRequested(this.enrollmentId);

  @override
  List<Object?> get props => [enrollmentId];
}

/// Étape Résumé : confirme le brouillon (DRAFT → PENDING_SYNC).
/// [finalStatus] : statut métier à écrire explicitement (PRE → `COMPLETED`) ;
/// `null` ne touche pas `status` (comportement NEW/RE inchangé).
class FinalizeDraftRequested extends EnrollmentOfflineEvent {
  final String enrollmentId;
  final bool emitDocument;
  final String? finalStatus;

  const FinalizeDraftRequested(
    this.enrollmentId, {
    this.emitDocument = true,
    this.finalStatus,
  });

  @override
  List<Object?> get props => [enrollmentId, emitDocument, finalStatus];
}
