import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

class EnrollmentSchoolDetail extends Equatable {
  final String id;
  final EnrollmentStatus status;
  final String academicYearId;
  final String enrollmentCode;
  final String previousSchoolName;
  final String previousAcademicYear;
  final String previousSchoolLevelGroup;
  final String previousSchoolLevel;

  /// Id référentiel du niveau N-1 (distinct du texte libre
  /// [previousSchoolLevel]) — vide si inconnu (hors réinscription, ou
  /// dossier créé avant l'introduction de ce champ). Alimente le calcul
  /// auto de la classe cible.
  final String previousSchoolLevelId;

  /// Moyenne de l'année précédente, **en pourcentage**. `null` = non
  /// renseignée, ce qui n'est PAS `0` : un enfant qui entre en première année
  /// de maternelle n'a pas de moyenne, il n'a pas eu zéro. Tout rendu doit
  /// distinguer les deux.
  final double? previousRate;
  final int? previousRank;

  /// Année précédente validée. **Tri-état** : `null` = personne ne l'a dit,
  /// et un dossier neuf part de là. Le rabattre sur `false` inventerait un
  /// redoublement — et le calcul automatique de la classe cible s'en sert.
  final bool? validatedPreviousYear;

  /// L'enfant a-t-il DÉJÀ été élève de cette école ? Déclaré au guichet, et
  /// **délibérément distinct du type d'inscription** : une école qui démarre
  /// sur l'application inscrit tous ses anciens élèves en NEW_ENROLLMENT,
  /// faute de dossier N-1. Jamais nul — la colonne ne l'est pas.
  final bool formerStudent;

  /// Fiche santé de l'enfant (allergies, traitement en cours, conduite à
  /// tenir). **Donnée de santé** : jamais imprimée sur une pièce, jamais
  /// journalisée, jamais recopiée dans un message d'erreur.
  final String? medicalNotes;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String? transferReason;
  final String? cancellationReason;

  const EnrollmentSchoolDetail({
    required this.id,
    required this.status,
    required this.academicYearId,
    required this.enrollmentCode,
    required this.previousSchoolName,
    required this.previousAcademicYear,
    required this.previousSchoolLevelGroup,
    required this.previousSchoolLevel,
    this.previousSchoolLevelId = '',
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.formerStudent = false,
    this.medicalNotes,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.transferReason,
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [
    id,
    status,
    academicYearId,
    enrollmentCode,
    previousSchoolName,
    previousAcademicYear,
    previousSchoolLevelGroup,
    previousSchoolLevel,
    previousSchoolLevelId,
    previousRate,
    previousRank,
    validatedPreviousYear,
    formerStudent,
    medicalNotes,
    schoolLevelGroupId,
    schoolLevelId,
    transferReason,
    cancellationReason,
  ];
}
