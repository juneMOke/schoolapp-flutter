import 'package:equatable/equatable.dart';

/// Candidat de **réinscription** lu localement dans `ref_previous_year_students`
/// (cohorte N-1 peuplée par le pull). Sert de **photo de départ** au brouillon
/// RE : identité + matricule (→ `source_ref`) + tuteur dénormalisé + antécédents
/// (ids). L'année cible (`academic_year_id`) n'est PAS ici — elle vient du
/// bootstrap courant au moment du seed.
class ReenrollmentCandidate extends Equatable {
  final String studentId;
  final String matriculationNumber;
  final String firstName;
  final String lastName;
  final String? surname;
  final String gender; // valeur API : MALE|FEMALE|OTHER
  final String dateOfBirth; // yyyy-MM-dd
  final String? birthPlace;
  final String? previousAcademicYearId;
  final String? previousSchoolLevelId;
  final String? previousClassroomId;
  final String? guardianName;
  final String? guardianPhone;
  final int previousBalanceInCents;
  final String? currency;

  /// Fiche santé du dossier N-1. **Une proposition, pas une valeur acquise** :
  /// elle ne devient celle du nouveau dossier que si le brouillon la reprend
  /// puis la repousse dans son agrégat. Un seed qui l'ignore fait perdre à
  /// l'enfant ses allergies au changement d'année — pendant que le guichet en
  /// ligne, lui, les conserve.
  final String? medicalNotes;

  /// Libellé du niveau N-1 (résolu localement depuis [previousSchoolLevelId]
  /// via `ref_school_levels` — le backend de la cohorte ne renvoie qu'un id).
  /// `null` si le référentiel N-1 n'est plus en cache (purge).
  final String? previousSchoolLevelName;

  /// Libellé du cycle N-1 (résolu via `ref_school_level_groups`), idem.
  final String? previousSchoolLevelGroupName;

  /// Nom de l'établissement N-1 : une réinscription se fait dans la MÊME
  /// école, donc résolu depuis `ref_school` (l'école courante) plutôt que
  /// porté par la cohorte (qui n'a pas ce champ).
  final String? previousSchoolName;

  const ReenrollmentCandidate({
    required this.studentId,
    required this.matriculationNumber,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.gender,
    required this.dateOfBirth,
    this.birthPlace,
    this.previousAcademicYearId,
    this.previousSchoolLevelId,
    this.previousClassroomId,
    this.guardianName,
    this.guardianPhone,
    this.previousBalanceInCents = 0,
    this.currency,
    this.medicalNotes,
    this.previousSchoolLevelName,
    this.previousSchoolLevelGroupName,
    this.previousSchoolName,
  });

  @override
  List<Object?> get props => [
    studentId,
    matriculationNumber,
    firstName,
    lastName,
    surname,
    gender,
    dateOfBirth,
    birthPlace,
    previousAcademicYearId,
    previousSchoolLevelId,
    previousClassroomId,
    guardianName,
    guardianPhone,
    previousBalanceInCents,
    currency,
    medicalNotes,
    previousSchoolLevelName,
    previousSchoolLevelGroupName,
    previousSchoolName,
  ];
}
